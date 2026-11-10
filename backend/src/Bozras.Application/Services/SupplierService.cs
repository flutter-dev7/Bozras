using Bozras.Application.Common;
using Bozras.Application.DTOs.Suppliers.Request;
using Bozras.Application.DTOs.Suppliers.Response;
using Bozras.Application.Interfaces.Repositories;
using Bozras.Application.Interfaces.Services;
using Bozras.Domain.Entities;
using Bozras.Domain.Enums;

namespace Bozras.Application.Services;

public class SupplierService : ISupplierService
{
    private const int TrialDays = 30;
    private const int UtcOffsetHours = 5;

    private readonly ISupplierRepository _suppliers;
    private readonly IPlanRepository _plans;
    private readonly ILocationRepository _locations;
    private readonly IUserRepository _users;
    private readonly IUnitOfWork _unitOfWork;
    private readonly TimeProvider _time;

    public SupplierService(
        ISupplierRepository suppliers,
        IPlanRepository plans,
        ILocationRepository locations,
        IUserRepository users,
        IUnitOfWork unitOfWork,
        TimeProvider time)
    {
        _suppliers = suppliers;
        _plans = plans;
        _locations = locations;
        _users = users;
        _unitOfWork = unitOfWork;
        _time = time;
    }

    public async Task<Result<PagedResult<SupplierResponse>>> GetPagedAsync(
        SupplierQueryRequest request, CancellationToken ct = default)
    {
        var page = Math.Max(request.Page, 1);
        var pageSize = Math.Clamp(request.PageSize, 1, 100);

        var (items, totalCount) = await _suppliers.GetPagedAsync(
            request.Search, request.IsActive, page, pageSize, ct);

        var stats = await _suppliers.GetStatsAsync(items.Select(s => s.Id).ToList(), ct);

        return Result<PagedResult<SupplierResponse>>.Success(new PagedResult<SupplierResponse>
        {
            Items = items.Select(s => ToResponse(s, stats.GetValueOrDefault(s.Id))).ToList(),
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize
        });
    }

    public async Task<Result<SupplierResponse>> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        var supplier = await _suppliers.GetByIdAsync(id, ct);
        if (supplier is null)
            return Result<SupplierResponse>.Failure("Поставщик не найден.", ErrorType.NotFound);

        return Result<SupplierResponse>.Success(await ToResponseAsync(supplier, ct));
    }

    public async Task<Result<SupplierResponse>> CreateAsync(
        CreateSupplierRequest request, CancellationToken ct = default)
    {
        var name = request.Name.Trim();
        if (name.Length == 0)
            return Result<SupplierResponse>.Failure("Укажите название.");

        var firstName = request.AdminFirstName.Trim();
        var lastName = request.AdminLastName.Trim();
        if (firstName.Length == 0 || lastName.Length == 0)
            return Result<SupplierResponse>.Failure("Укажите имя и фамилию админа.");

        var email = EmailNormalizer.Normalize(request.AdminEmail);
        if (email is null)
            return Result<SupplierResponse>.Failure("Неверный email админа.");

        var adminPhone = PhoneNumberNormalizer.Normalize(request.AdminPhone);
        if (adminPhone is null)
            return Result<SupplierResponse>.Failure("Неверный номер телефона админа.");

        if (await _users.GetByEmailAsync(email, ct) is not null)
            return Result<SupplierResponse>.Failure("Пользователь с таким email уже существует.", ErrorType.Conflict);

        if (await _users.GetByPhoneAsync(adminPhone, ct) is not null)
            return Result<SupplierResponse>.Failure("Пользователь с таким номером уже существует.", ErrorType.Conflict);

        var error = await ValidatePlanAndLocationsAsync(request.PlanId, request.LocationIds, ct);
        if (error is not null)
            return Result<SupplierResponse>.Failure(error);

        var supplier = new Supplier
        {
            Name = name,
            Code = await GenerateUniqueCodeAsync(ct),
            Phone = NormalizeOptionalPhone(request.Phone),
            Description = NormalizeOptional(request.Description),
            RequiresApproval = request.RequiresApproval,
            PlanId = request.PlanId,
            IsActive = true,
            SubscriptionStatus = SubscriptionStatus.Trial,
            SubscriptionEndsAt = _time.GetUtcNow().UtcDateTime.AddDays(TrialDays)
        };

        foreach (var locationId in request.LocationIds.Distinct())
            supplier.ServiceAreas.Add(new ServiceArea { LocationId = locationId });

        var admin = new User
        {
            FirstName = firstName,
            LastName = lastName,
            Phone = adminPhone,
            Email = email,
            EmailConfirmed = false,
            Role = UserRole.Admin,
            IsActive = true,
            Supplier = supplier
        };

        await _suppliers.AddAsync(supplier, ct);
        await _users.AddAsync(admin, ct);
        await _unitOfWork.SaveChangesAsync(ct);

        return await GetByIdAsync(supplier.Id, ct);
    }

    public async Task<Result<SupplierResponse>> UpdateAsync(
        Guid id, UpdateSupplierRequest request, CancellationToken ct = default)
    {
        var supplier = await _suppliers.GetByIdAsync(id, ct);
        if (supplier is null)
            return Result<SupplierResponse>.Failure("Поставщик не найден.", ErrorType.NotFound);

        var name = request.Name.Trim();
        if (name.Length == 0)
            return Result<SupplierResponse>.Failure("Укажите название.");

        var error = await ValidatePlanAndLocationsAsync(request.PlanId, request.LocationIds, ct);
        if (error is not null)
            return Result<SupplierResponse>.Failure(error);

        supplier.Name = name;
        supplier.Phone = NormalizeOptionalPhone(request.Phone);
        supplier.Description = NormalizeOptional(request.Description);
        supplier.PlanId = request.PlanId;
        supplier.RequiresApproval = request.RequiresApproval;
        supplier.IsActive = request.IsActive;

        var wanted = request.LocationIds.Distinct().ToHashSet();

        foreach (var area in supplier.ServiceAreas.Where(a => !wanted.Contains(a.LocationId)).ToList())
            supplier.ServiceAreas.Remove(area);

        var existing = supplier.ServiceAreas.Select(a => a.LocationId).ToHashSet();

        foreach (var locationId in wanted.Where(l => !existing.Contains(l)))
            supplier.ServiceAreas.Add(new ServiceArea { LocationId = locationId });

        await _unitOfWork.SaveChangesAsync(ct);

        return await GetByIdAsync(id, ct);
    }

    public async Task<Result<SupplierResponse>> RegenerateCodeAsync(Guid id, CancellationToken ct = default)
    {
        var supplier = await _suppliers.GetByIdAsync(id, ct);
        if (supplier is null)
            return Result<SupplierResponse>.Failure("Поставщик не найден.", ErrorType.NotFound);

        supplier.Code = await GenerateUniqueCodeAsync(ct);
        await _unitOfWork.SaveChangesAsync(ct);

        return await GetByIdAsync(id, ct);
    }

    public async Task<Result<List<SubscriptionPaymentResponse>>> GetPaymentsAsync(
        Guid id, CancellationToken ct = default)
    {
        var supplier = await _suppliers.GetByIdAsync(id, ct);
        if (supplier is null)
            return Result<List<SubscriptionPaymentResponse>>.Failure("Поставщик не найден.", ErrorType.NotFound);

        var payments = await _suppliers.GetPaymentsAsync(id, ct);

        return Result<List<SubscriptionPaymentResponse>>.Success(payments.Select(ToPaymentResponse).ToList());
    }

    public async Task<Result<SubscriptionPaymentResponse>> RecordPaymentAsync(
        Guid id, RecordSubscriptionPaymentRequest request, Guid userId, CancellationToken ct = default)
    {
        var supplier = await _suppliers.GetByIdAsync(id, ct);
        if (supplier is null)
            return Result<SubscriptionPaymentResponse>.Failure("Поставщик не найден.", ErrorType.NotFound);

        var planId = request.PlanId ?? supplier.PlanId;
        Plan? plan = null;

        if (planId.HasValue)
        {
            plan = await _plans.GetByIdAsync(planId.Value, ct);
            if (plan is null)
                return Result<SubscriptionPaymentResponse>.Failure("Тариф не найден.", ErrorType.NotFound);
        }

        var nowUtc = _time.GetUtcNow().UtcDateTime;
        var today = DateOnly.FromDateTime(nowUtc.AddHours(UtcOffsetHours));

        var currentEnd = supplier.SubscriptionEndsAt.HasValue
            ? DateOnly.FromDateTime(supplier.SubscriptionEndsAt.Value.AddHours(UtcOffsetHours))
            : today;

        var from = currentEnd > today ? currentEnd : today;
        var to = from.AddMonths(request.Months);

        var payment = new SubscriptionPayment
        {
            SupplierId = supplier.Id,
            PlanId = plan?.Id,
            Amount = request.Amount,
            Method = request.Method,
            PeriodFrom = from,
            PeriodTo = to,
            Note = NormalizeOptional(request.Note),
            CreatedByUserId = userId
        };

        supplier.SubscriptionEndsAt = DateTime
            .SpecifyKind(to.ToDateTime(TimeOnly.MaxValue), DateTimeKind.Utc)
            .AddHours(-UtcOffsetHours);
        supplier.SubscriptionStatus = SubscriptionStatus.Active;

        if (plan is not null)
            supplier.PlanId = plan.Id;

        await _suppliers.AddPaymentAsync(payment, ct);
        await _unitOfWork.SaveChangesAsync(ct);

        payment.Plan = plan;

        return Result<SubscriptionPaymentResponse>.Success(ToPaymentResponse(payment));
    }

    private async Task<string?> ValidatePlanAndLocationsAsync(
        Guid? planId, IEnumerable<Guid> locationIds, CancellationToken ct)
    {
        if (planId.HasValue && await _plans.GetByIdAsync(planId.Value, ct) is null)
            return "Тариф не найден.";

        var ids = locationIds.Distinct().ToList();

        if (ids.Count > 0 && await _locations.CountExistingAsync(ids, ct) != ids.Count)
            return "Некоторые города или районы не найдены.";

        return null;
    }

    private async Task<string> GenerateUniqueCodeAsync(CancellationToken ct)
    {
        for (var attempt = 0; attempt < 20; attempt++)
        {
            var code = SupplierCodeGenerator.Generate();

            if (!await _suppliers.CodeExistsAsync(code, ct))
                return code;
        }

        throw new InvalidOperationException("Не удалось создать уникальный код поставщика.");
    }

    private async Task<SupplierResponse> ToResponseAsync(Supplier supplier, CancellationToken ct)
    {
        var stats = await _suppliers.GetStatsAsync(new[] { supplier.Id }, ct);

        return ToResponse(supplier, stats.GetValueOrDefault(supplier.Id));
    }

    private SupplierResponse ToResponse(Supplier supplier, SupplierStats? stats) => new()
    {
        Id = supplier.Id,
        Name = supplier.Name,
        Code = supplier.Code,
        Phone = supplier.Phone,
        Description = supplier.Description,
        IsActive = supplier.IsActive,
        RequiresApproval = supplier.RequiresApproval,
        PlanId = supplier.PlanId,
        PlanName = supplier.Plan?.Name,
        SubscriptionStatus = supplier.SubscriptionStatus.ToString(),
        SubscriptionEndsAt = supplier.SubscriptionEndsAt,
        IsAccessAllowed = SubscriptionRules.IsAccessAllowed(
            supplier.IsActive, supplier.SubscriptionStatus, supplier.SubscriptionEndsAt,
            _time.GetUtcNow().UtcDateTime),
        ShopsCount = stats?.Shops ?? 0,
        StaffCount = stats?.Staff ?? 0,
        AdminEmail = stats?.AdminEmail,
        LocationIds = supplier.ServiceAreas.Select(a => a.LocationId).ToList(),
        CreatedAt = supplier.CreatedAt
    };

    private static SubscriptionPaymentResponse ToPaymentResponse(SubscriptionPayment payment) => new()
    {
        Id = payment.Id,
        Amount = payment.Amount,
        Method = payment.Method.ToString(),
        PlanName = payment.Plan?.Name,
        PeriodFrom = payment.PeriodFrom,
        PeriodTo = payment.PeriodTo,
        Note = payment.Note,
        CreatedAt = payment.CreatedAt
    };

    private static string? NormalizeOptional(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();

    private static string? NormalizeOptionalPhone(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : PhoneNumberNormalizer.Normalize(value) ?? value.Trim();
}