using Bozras.Application.Common;
using Bozras.Application.DTOs.Connections.Response;
using Bozras.Application.DTOs.Shops.Request;
using Bozras.Application.DTOs.Shops.Response;
using Bozras.Application.Interfaces.Repositories;
using Bozras.Application.Interfaces.Services;
using Bozras.Domain.Entities;
using Bozras.Domain.Enums;

namespace Bozras.Application.Services;

public class ShopService : IShopService
{
    private readonly IShopRepository _shopRepository;
    private readonly IUserRepository _userRepository;
    private readonly IUnitOfWork _unitOfWork;

    public ShopService(
        IShopRepository shopRepository,
        IUserRepository userRepository,
        IUnitOfWork unitOfWork)
    {
        _shopRepository = shopRepository;
        _userRepository = userRepository;
        _unitOfWork = unitOfWork;
    }

    public async Task<Result<PagedResult<ShopResponse>>> GetPagedAsync(
        ShopQueryRequest request, CancellationToken ct = default)
    {
        var page = Math.Max(request.Page, 1);
        var pageSize = Math.Clamp(request.PageSize, 1, 100);

        var (items, totalCount) = await _shopRepository.GetPagedAsync(
            request.Search, request.IsActive, page, pageSize, ct);

        return Result<PagedResult<ShopResponse>>.Success(new PagedResult<ShopResponse>
        {
            Items = items.Select(ToResponse).ToList(),
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize
        });
    }

    public async Task<Result<ShopResponse>> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        var shop = await _shopRepository.GetDetailsByIdAsync(id, ct);
        if (shop is null)
            return Result<ShopResponse>.Failure("Магазин не найден.", ErrorType.NotFound);

        return Result<ShopResponse>.Success(ToResponse(shop));
    }

    public async Task<Result<ShopResponse>> GetMyAsync(Guid userId, CancellationToken ct = default)
    {
        var shop = await _shopRepository.GetDetailsByOwnerIdAsync(userId, ct);
        if (shop is null)
            return Result<ShopResponse>.Failure("У вас ещё нет магазина.", ErrorType.NotFound);

        return Result<ShopResponse>.Success(ToResponse(shop));
    }

    public Task<Result<ShopResponse>> CreateAsync(CreateShopRequest request, CancellationToken ct = default) =>
        CreateInternalAsync(request, null, ct);

    public async Task<Result<ShopResponse>> CreateMyAsync(
        Guid userId, CreateShopRequest request, CancellationToken ct = default)
    {
        if (await _shopRepository.OwnerHasShopAsync(userId, null, ct))
            return Result<ShopResponse>.Failure("У вас уже есть магазин.", ErrorType.Conflict);

        return await CreateInternalAsync(request, userId, ct);
    }

    public async Task<Result<ShopResponse>> UpdateAsync(
        Guid id, UpdateShopRequest request, CancellationToken ct = default)
    {
        var shop = await _shopRepository.GetByIdAsync(id, ct);
        if (shop is null)
            return Result<ShopResponse>.Failure("Магазин не найден.", ErrorType.NotFound);

        var phone = PhoneNumberNormalizer.Normalize(request.Phone);
        if (phone is null)
            return Result<ShopResponse>.Failure("Неверный номер телефона.");
        
        var locationError = ValidateLocation(request.Latitude, request.Longitude);
        if (locationError is not null)
            return Result<ShopResponse>.Failure(locationError);

        shop.Name = request.Name.Trim();
        shop.Address = request.Address.Trim();
        shop.Phone = phone;
        shop.ContactName = NormalizeOptional(request.ContactName);
        shop.IsActive = request.IsActive;
        
        if (request.Latitude.HasValue && request.Longitude.HasValue)
        {
            shop.Latitude = RoundCoordinate(request.Latitude.Value);
            shop.Longitude = RoundCoordinate(request.Longitude.Value);
        }

        await _unitOfWork.SaveChangesAsync(ct);

        return await ReloadAsync(shop.Id, ct);
    }

    public async Task<Result<ShopResponse>> SetOwnerAsync(
        Guid id, SetOwnerRequest request, CancellationToken ct = default)
    {
        var shop = await _shopRepository.GetByIdAsync(id, ct);
        if (shop is null)
            return Result<ShopResponse>.Failure("Магазин не найден.", ErrorType.NotFound);

        if (string.IsNullOrWhiteSpace(request.OwnerPhone))
        {
            shop.UserId = null;
            await _unitOfWork.SaveChangesAsync(ct);

            return await ReloadAsync(shop.Id, ct);
        }

        var phone = PhoneNumberNormalizer.Normalize(request.OwnerPhone);
        if (phone is null)
            return Result<ShopResponse>.Failure("Неверный номер телефона.");

        var user = await _userRepository.GetByPhoneAsync(phone, ct);
        if (user is null)
            return Result<ShopResponse>.Failure("Пользователь с таким номером не найден.", ErrorType.NotFound);

        if (user.Role != UserRole.Shop)
            return Result<ShopResponse>.Failure("Владельцем магазина может быть только пользователь с ролью Shop.");

        if (await _shopRepository.OwnerHasShopAsync(user.Id, id, ct))
            return Result<ShopResponse>.Failure("За этим пользователем уже закреплён другой магазин.", ErrorType.Conflict);

        shop.UserId = user.Id;
        await _unitOfWork.SaveChangesAsync(ct);

        return await ReloadAsync(shop.Id, ct);
    }

    public async Task<Result<ShopResponse>> SetDebtLimitAsync(
        Guid id, SetDebtLimitRequest request, CancellationToken ct = default)
    {
        var shop = await _shopRepository.GetByIdAsync(id, ct);
        if (shop is null)
            return Result<ShopResponse>.Failure("Магазин не найден.", ErrorType.NotFound);

        shop.DebtLimit = request.DebtLimit;
        await _unitOfWork.SaveChangesAsync(ct);

        return await ReloadAsync(shop.Id, ct);
    }
    
    public async Task<Result<List<ShopRequestResponse>>> GetRequestsAsync(CancellationToken ct = default)
    {
        var shops = await _shopRepository.GetByStatusAsync(ShopConnectionStatus.Pending, ct);

        var items = shops.Select(s => new ShopRequestResponse
        {
            Id = s.Id,
            Name = s.Name,
            Address = s.Address,
            Phone = s.Phone,
            ContactName = s.ContactName,
            Latitude = s.Latitude,
            Longitude = s.Longitude,
            OwnerName = s.User?.FullName,
            OwnerPhone = s.User?.Phone
        }).ToList();

        return Result<List<ShopRequestResponse>>.Success(items);
    }

    public Task<Result> ApproveAsync(Guid id, CancellationToken ct = default) =>
        ResolveRequestAsync(id, ShopConnectionStatus.Active, ct);

    public Task<Result> RejectAsync(Guid id, CancellationToken ct = default) =>
        ResolveRequestAsync(id, ShopConnectionStatus.Rejected, ct);

    private async Task<Result> ResolveRequestAsync(Guid id, ShopConnectionStatus target, CancellationToken ct)
    {
        var shop = await _shopRepository.GetByIdAsync(id, ct);
        if (shop is null)
            return Result.Failure("Заявка не найдена.", ErrorType.NotFound);

        if (shop.Status != ShopConnectionStatus.Pending)
            return Result.Failure("Заявка уже обработана.", ErrorType.Conflict);

        shop.Status = target;
        await _unitOfWork.SaveChangesAsync(ct);

        return Result.Success();
    }

    private async Task<Result<ShopResponse>> CreateInternalAsync(
        CreateShopRequest request, Guid? ownerId, CancellationToken ct)
    {
        var phone = PhoneNumberNormalizer.Normalize(request.Phone);
        if (phone is null)
            return Result<ShopResponse>.Failure("Неверный номер телефона.");
        
        var locationError = ValidateLocation(request.Latitude, request.Longitude);
        if (locationError is not null)
            return Result<ShopResponse>.Failure(locationError);

        var shop = new Shop
        {
            Name = request.Name.Trim(),
            Address = request.Address.Trim(),
            Phone = phone,
            ContactName = NormalizeOptional(request.ContactName),
            Latitude = request.Latitude.HasValue ? RoundCoordinate(request.Latitude.Value) : null,
            Longitude = request.Longitude.HasValue ? RoundCoordinate(request.Longitude.Value) : null,
            UserId = ownerId,
            IsActive = true
        };

        await _shopRepository.AddAsync(shop, ct);
        await _unitOfWork.SaveChangesAsync(ct);

        return await ReloadAsync(shop.Id, ct);
    }
    
    public async Task<Result<ShopResponse>> SetLocationAsync(
        Guid id, SetLocationRequest request, CancellationToken ct = default)
    {
        var shop = await _shopRepository.GetByIdAsync(id, ct);
        if (shop is null)
            return Result<ShopResponse>.Failure("Магазин не найден.", ErrorType.NotFound);

        return await ApplyLocationAsync(shop, request, ct);
    }

    public async Task<Result<ShopResponse>> SetMyLocationAsync(
        Guid userId, SetLocationRequest request, CancellationToken ct = default)
    {
        var shop = await _shopRepository.GetByOwnerIdAsync(userId, ct);
        if (shop is null)
            return Result<ShopResponse>.Failure("У вас ещё нет магазина.", ErrorType.NotFound);

        return await ApplyLocationAsync(shop, request, ct);
    }

    private async Task<Result<ShopResponse>> ReloadAsync(Guid id, CancellationToken ct)
    {
        var shop = await _shopRepository.GetDetailsByIdAsync(id, ct);

        return Result<ShopResponse>.Success(ToResponse(shop!));
    }

    private static string? NormalizeOptional(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();
    
    private async Task<Result<ShopResponse>> ApplyLocationAsync(
        Shop shop, SetLocationRequest request, CancellationToken ct)
    {
        var error = ValidateLocation(request.Latitude, request.Longitude);
        if (error is not null)
            return Result<ShopResponse>.Failure(error);

        shop.Latitude = request.Latitude.HasValue ? RoundCoordinate(request.Latitude.Value) : null;
        shop.Longitude = request.Longitude.HasValue ? RoundCoordinate(request.Longitude.Value) : null;

        await _unitOfWork.SaveChangesAsync(ct);

        return await ReloadAsync(shop.Id, ct);
    }

    private static string? ValidateLocation(double? latitude, double? longitude) =>
        latitude.HasValue != longitude.HasValue ? "Укажите и широту, и долготу." : null;

    private static double RoundCoordinate(double value) => Math.Round(value, 6);

    private static ShopResponse ToResponse(Shop shop) => new()
    {
        Id = shop.Id,
        Name = shop.Name,
        Address = shop.Address,
        Phone = shop.Phone,
        ContactName = shop.ContactName,
        Latitude = shop.Latitude,
        Longitude = shop.Longitude,
        DebtLimit = shop.DebtLimit,
        IsActive = shop.IsActive,
        OwnerUserId = shop.UserId,
        OwnerPhone = shop.User?.Phone,
        OwnerName = shop.User?.FullName
    };
}