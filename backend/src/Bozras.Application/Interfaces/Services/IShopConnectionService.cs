using Bozras.Application.Common;
using Bozras.Application.DTOs.Connections.Request;
using Bozras.Application.DTOs.Connections.Response;

namespace Bozras.Application.Interfaces.Services;

public interface IShopConnectionService
{
    Task<Result<ShopProfileResponse>> GetProfileAsync(Guid userId, CancellationToken ct = default);
    Task<Result<ShopProfileResponse>> SaveProfileAsync(Guid userId, SaveShopProfileRequest request, CancellationToken ct = default);
    Task<Result<List<SupplierCardResponse>>> GetNearbyAsync(Guid userId, string? search, CancellationToken ct = default);
    Task<Result<List<MySupplierResponse>>> GetMySuppliersAsync(Guid userId, CancellationToken ct = default);
    Task<Result<SupplierCardResponse>> ConnectAsync(Guid userId, ConnectSupplierRequest request, CancellationToken ct = default);
    Task<Result<SupplierCardResponse>> ConnectToSupplierAsync(Guid userId, Guid supplierId, CancellationToken ct = default);
}