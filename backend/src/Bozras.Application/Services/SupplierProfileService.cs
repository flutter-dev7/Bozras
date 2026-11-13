using Bozras.Application.Common;
using Bozras.Application.DTOs.Connections.Request;
using Bozras.Application.DTOs.Connections.Response;
using Bozras.Application.Interfaces.Repositories;
using Bozras.Application.Interfaces.Services;
using Bozras.Domain.Entities;
using Bozras.Domain.Enums;

namespace Bozras.Application.Services;

public class SupplierProfileService : ISupplierProfileService
{
    private readonly IConnectionRepository _repository;
    private readonly ITenantContext _tenant;
    private readonly IUnitOfWork _unitOfWork;

    public SupplierProfileService(
        IConnectionRepository repository,
        ITenantContext tenant,
        IUnitOfWork unitOfWork)
    {
        _repository = repository;
        _tenant = tenant;
        _unitOfWork = unitOfWork;
    }

    public async Task<Result<SupplierProfileResponse>> GetAsync(CancellationToken ct = default)
    {
        var supplier = await _repository.GetSupplierAsync(_tenant.RequireSupplierId(), true, ct);
        if (supplier is null)
            return Result<SupplierProfileResponse>.Failure("Поставщик не найден.", ErrorType.NotFound);

        return Result<SupplierProfileResponse>.Success(ToResponse(supplier));
    }

    public async Task<Result<SupplierProfileResponse>> UpdateAsync(
        UpdateSupplierProfileRequest request, CancellationToken ct = default)
    {
        var supplier = await _repository.GetSupplierAsync(_tenant.RequireSupplierId(), true, ct);
        if (supplier is null)
            return Result<SupplierProfileResponse>.Failure("Поставщик не найден.", ErrorType.NotFound);

        string? phone = null;

        if (!string.IsNullOrWhiteSpace(request.Phone))
        {
            phone = PhoneNumberNormalizer.Normalize(request.Phone);
            if (phone is null)
                return Result<SupplierProfileResponse>.Failure("Неверный номер телефона.");
        }

        supplier.Phone = phone;
        supplier.Description = string.IsNullOrWhiteSpace(request.Description) ? null : request.Description.Trim();
        supplier.RequiresApproval = request.RequiresApproval;

        await _unitOfWork.SaveChangesAsync(ct);

        return Result<SupplierProfileResponse>.Success(ToResponse(supplier));
    }

    public async Task<Result<SupplierProfileResponse>> RegenerateCodeAsync(CancellationToken ct = default)
    {
        var supplier = await _repository.GetSupplierAsync(_tenant.RequireSupplierId(), true, ct);
        if (supplier is null)
            return Result<SupplierProfileResponse>.Failure("Поставщик не найден.", ErrorType.NotFound);

        for (var attempt = 0; attempt < 10; attempt++)
        {
            var code = SupplierCodeGenerator.Generate();

            if (await _repository.CodeExistsAsync(code, ct))
                continue;

            supplier.Code = code;
            await _unitOfWork.SaveChangesAsync(ct);

            return Result<SupplierProfileResponse>.Success(ToResponse(supplier));
        }

        return Result<SupplierProfileResponse>.Failure("Не удалось создать код, попробуйте ещё раз.", ErrorType.Failure);
    }

    private static SupplierProfileResponse ToResponse(Supplier s) => new()
    {
        Id = s.Id,
        Name = s.Name,
        Code = s.Code,
        Phone = s.Phone,
        Description = s.Description,
        LogoUrl = s.LogoUrl,
        RequiresApproval = s.RequiresApproval,
        PlanName = s.Plan?.Name,
        SubscriptionStatus = s.SubscriptionStatus,
        SubscriptionEndsAt = s.SubscriptionEndsAt
    };
}