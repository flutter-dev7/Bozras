namespace Bozras.Application.Interfaces.Services;

public interface IPlanLimitService
{
    Task<string?> CheckShopLimitAsync(Guid supplierId, CancellationToken ct = default);

    Task<string?> CheckStaffLimitAsync(Guid supplierId, CancellationToken ct = default);
}