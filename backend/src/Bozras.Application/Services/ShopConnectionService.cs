using Bozras.Application.Common;
using Bozras.Application.DTOs.Connections.Request;
using Bozras.Application.DTOs.Connections.Response;
using Bozras.Application.Interfaces.Repositories;
using Bozras.Application.Interfaces.Services;
using Bozras.Domain.Entities;
using Bozras.Domain.Enums;

namespace Bozras.Application.Services;

public class ShopConnectionService : IShopConnectionService
{
    private readonly IConnectionRepository _repository;
    private readonly ITenantAccessService _access;
    private readonly IUnitOfWork _unitOfWork;
    private readonly IPlanLimitService _limits;
    private readonly IShopRequestNotifier _requestNotifier;

    public ShopConnectionService(
        IConnectionRepository repository,
        ITenantAccessService access,
        IUnitOfWork unitOfWork,
        IPlanLimitService limits,
        IShopRequestNotifier requestNotifier)
    {
        _repository = repository;
        _access = access;
        _unitOfWork = unitOfWork;
        _limits = limits;
        _requestNotifier = requestNotifier;
    }

    public async Task<Result<ShopProfileResponse>> GetProfileAsync(Guid userId, CancellationToken ct = default)
    {
        var profile = await _repository.GetProfileAsync(userId, ct);
        if (profile is null)
            return Result<ShopProfileResponse>.Failure("Профиль магазина не заполнен.", ErrorType.NotFound);

        return Result<ShopProfileResponse>.Success(ToResponse(profile));
    }

    public async Task<Result<ShopProfileResponse>> SaveProfileAsync(
        Guid userId, SaveShopProfileRequest request, CancellationToken ct = default)
    {
        var phone = PhoneNumberNormalizer.Normalize(request.Phone);
        if (phone is null)
            return Result<ShopProfileResponse>.Failure("Неверный номер телефона.");

        if (string.IsNullOrWhiteSpace(request.Name) || string.IsNullOrWhiteSpace(request.Address))
            return Result<ShopProfileResponse>.Failure("Укажите название и адрес магазина.");

        if (request.Latitude.HasValue != request.Longitude.HasValue)
            return Result<ShopProfileResponse>.Failure("Укажите и широту, и долготу.");

        if (request.LocationId is null || !await _repository.LocationExistsAsync(request.LocationId.Value, ct))
            return Result<ShopProfileResponse>.Failure("Выберите регион из списка.");

        var profile = await _repository.GetProfileAsync(userId, ct);

        if (profile is null)
        {
            profile = new ShopProfile { UserId = userId };
            await _repository.AddProfileAsync(profile, ct);
        }

        profile.Name = request.Name.Trim();
        profile.Address = request.Address.Trim();
        profile.Phone = phone;
        profile.ContactName = string.IsNullOrWhiteSpace(request.ContactName) ? null : request.ContactName.Trim();
        profile.LocationId = request.LocationId;
        profile.Latitude = request.Latitude.HasValue ? Math.Round(request.Latitude.Value, 6) : null;
        profile.Longitude = request.Longitude.HasValue ? Math.Round(request.Longitude.Value, 6) : null;

        await _unitOfWork.SaveChangesAsync(ct);

        return await GetProfileAsync(userId, ct);
    }

    public async Task<Result<List<SupplierCardResponse>>> GetNearbyAsync(
        Guid userId, string? search, CancellationToken ct = default)
    {
        var profile = await _repository.GetProfileAsync(userId, ct);
        if (profile?.LocationId is null)
            return Result<List<SupplierCardResponse>>.Failure("Укажите регион в профиле магазина.");

        var chain = await _repository.GetLocationChainAsync(profile.LocationId.Value, ct);
        var suppliers = await _repository.GetNearbySuppliersAsync(chain, search, ct);
        var links = (await _repository.GetLinksAsync(userId, ct)).ToDictionary(l => l.SupplierId, l => l.Status);

        var items = suppliers
            .Select(s => ToCard(s, links.TryGetValue(s.Id, out var status) ? status : null))
            .ToList();

        return Result<List<SupplierCardResponse>>.Success(items);
    }

    public async Task<Result<List<MySupplierResponse>>> GetMySuppliersAsync(
        Guid userId, CancellationToken ct = default)
    {
        var links = await _repository.GetLinksAsync(userId, ct);

        var items = links
            .OrderBy(l => l.Name)
            .Select(l => new MySupplierResponse
            {
                SupplierId = l.SupplierId,
                Name = l.Name,
                Phone = l.Phone,
                Description = l.Description,
                LogoUrl = l.LogoUrl,
                Status = l.Status,
                IsAvailable = l.IsAvailable
            })
            .ToList();

        return Result<List<MySupplierResponse>>.Success(items);
    }

        public async Task<Result<SupplierCardResponse>> ConnectAsync(
        Guid userId, ConnectSupplierRequest request, CancellationToken ct = default)
    {
        var profile = await _repository.GetProfileAsync(userId, ct);
        if (profile is null)
            return Result<SupplierCardResponse>.Failure("Сначала заполните профиль магазина.");

        var code = request.Code.Trim().ToUpperInvariant();

        var supplier = await _repository.GetSupplierByCodeAsync(code, ct);
        if (supplier is null)
            return Result<SupplierCardResponse>.Failure("Поставщик с таким кодом не найден.", ErrorType.NotFound);

        return await CreateConnectionAsync(userId, profile, supplier, ct);
    }

    public async Task<Result<SupplierCardResponse>> ConnectToSupplierAsync(
        Guid userId, Guid supplierId, CancellationToken ct = default)
    {
        var profile = await _repository.GetProfileAsync(userId, ct);
        if (profile?.LocationId is null)
            return Result<SupplierCardResponse>.Failure("Сначала заполните профиль магазина.");

        var chain = await _repository.GetLocationChainAsync(profile.LocationId.Value, ct);
        var nearby = await _repository.GetNearbySuppliersAsync(chain, null, ct);

        var supplier = nearby.FirstOrDefault(s => s.Id == supplierId);
        if (supplier is null)
            return Result<SupplierCardResponse>.Failure(
                "Этот поставщик не обслуживает ваш регион.", ErrorType.Forbidden);

        return await CreateConnectionAsync(userId, profile, supplier, ct);
    }

    private async Task<Result<SupplierCardResponse>> CreateConnectionAsync(
        Guid userId, ShopProfile profile, Supplier supplier, CancellationToken ct)
    {
        if (!await _access.IsSupplierAvailableAsync(supplier.Id, ct))
            return Result<SupplierCardResponse>.Failure("Поставщик временно недоступен.", ErrorType.Forbidden);

        var existing = await _repository.GetUserShopAsync(userId, supplier.Id, ct);
        if (existing is not null)
        {
            var message = existing.Status switch
            {
                ShopConnectionStatus.Active => "Вы уже подключены к этому поставщику.",
                ShopConnectionStatus.Pending => "Заявка уже отправлена и ждёт одобрения.",
                _ => "Поставщик отклонил вашу заявку."
            };

            return Result<SupplierCardResponse>.Failure(message, ErrorType.Conflict);
        }
        
        if (await _limits.CheckShopLimitAsync(supplier.Id, ct) is not null)
            return Result<SupplierCardResponse>.Failure(
                "Поставщик сейчас не принимает новые магазины.", ErrorType.Forbidden);

        var shop = new Shop
        {
            SupplierId = supplier.Id,
            Name = profile.Name,
            Address = profile.Address,
            Phone = profile.Phone,
            ContactName = profile.ContactName,
            Latitude = profile.Latitude,
            Longitude = profile.Longitude,
            UserId = userId,
            ProfileId = profile.Id,
            IsActive = true,
            Status = supplier.RequiresApproval ? ShopConnectionStatus.Pending : ShopConnectionStatus.Active
        };

        await _repository.AddShopAsync(shop, ct);
        await _unitOfWork.SaveChangesAsync(ct);

        if (shop.Status == ShopConnectionStatus.Pending)
            await _requestNotifier.NotifyAsync(supplier.Id, shop.Name, ct);

        return Result<SupplierCardResponse>.Success(ToCard(supplier, shop.Status));
    }

    private static ShopProfileResponse ToResponse(ShopProfile p) => new()
    {
        Id = p.Id,
        Name = p.Name,
        Address = p.Address,
        Phone = p.Phone,
        ContactName = p.ContactName,
        LocationId = p.LocationId,
        LocationName = p.Location?.Name,
        Latitude = p.Latitude,
        Longitude = p.Longitude
    };

    private static SupplierCardResponse ToCard(Supplier s, ShopConnectionStatus? status) => new()
    {
        Id = s.Id,
        Name = s.Name,
        Phone = s.Phone,
        Description = s.Description,
        LogoUrl = s.LogoUrl,
        RequiresApproval = s.RequiresApproval,
        ConnectionStatus = status
    };
}