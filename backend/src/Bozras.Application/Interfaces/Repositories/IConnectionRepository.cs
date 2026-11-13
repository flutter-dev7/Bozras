using Bozras.Application.Common;
using Bozras.Domain.Entities;

namespace Bozras.Application.Interfaces.Repositories;

public interface IConnectionRepository
{
    Task<ShopProfile?> GetProfileAsync(Guid userId, CancellationToken ct = default);
    Task AddProfileAsync(ShopProfile profile, CancellationToken ct = default);
    Task<bool> LocationExistsAsync(Guid locationId, CancellationToken ct = default);
    Task<List<Guid>> GetLocationChainAsync(Guid locationId, CancellationToken ct = default);

    Task<List<Supplier>> GetNearbySuppliersAsync(
        IReadOnlyCollection<Guid> locationIds, string? search, CancellationToken ct = default);

    Task<Supplier?> GetSupplierByCodeAsync(string code, CancellationToken ct = default);
    Task<List<ShopSupplierLink>> GetLinksAsync(Guid userId, CancellationToken ct = default);
    Task<Shop?> GetUserShopAsync(Guid userId, Guid supplierId, CancellationToken ct = default);
    Task AddShopAsync(Shop shop, CancellationToken ct = default);

    Task<Supplier?> GetSupplierAsync(Guid id, bool withPlan, CancellationToken ct = default);
    Task<bool> CodeExistsAsync(string code, CancellationToken ct = default);
}