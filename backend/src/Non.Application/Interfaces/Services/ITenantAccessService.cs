namespace Non.Application.Interfaces.Services;

public interface ITenantAccessService
{
    Task<bool> SupplierExistsAsync(Guid supplierId, CancellationToken ct = default);

    Task<bool> IsSupplierAvailableAsync(Guid supplierId, CancellationToken ct = default);

    Task<bool> IsShopConnectedAsync(Guid userId, Guid supplierId, CancellationToken ct = default);
}