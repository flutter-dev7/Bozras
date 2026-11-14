using Bozras.Application.Interfaces.Repositories;
using Bozras.Application.Interfaces.Services;

namespace Bozras.Application.Services;

public class PlanLimitService : IPlanLimitService
{
    private readonly ISupplierRepository _suppliers;

    public PlanLimitService(ISupplierRepository suppliers)
    {
        _suppliers = suppliers;
    }

    public async Task<string?> CheckShopLimitAsync(Guid supplierId, CancellationToken ct = default)
    {
        var supplier = await _suppliers.GetByIdAsync(supplierId, ct);
        if (supplier is null)
            return "Поставщик не найден.";

        var max = supplier.Plan?.MaxShops;
        if (max is null)
            return null;

        var stats = await _suppliers.GetStatsAsync(new[] { supplierId }, ct);
        var count = stats.GetValueOrDefault(supplierId)?.Shops ?? 0;

        return count >= max
            ? $"Достигнут лимит тарифа: максимум магазинов — {max}."
            : null;
    }

    public async Task<string?> CheckStaffLimitAsync(Guid supplierId, CancellationToken ct = default)
    {
        var supplier = await _suppliers.GetByIdAsync(supplierId, ct);
        if (supplier is null)
            return "Поставщик не найден.";

        var max = supplier.Plan?.MaxStaff;
        if (max is null)
            return null;

        var stats = await _suppliers.GetStatsAsync(new[] { supplierId }, ct);
        var count = stats.GetValueOrDefault(supplierId)?.Staff ?? 0;

        return count >= max
            ? $"Достигнут лимит тарифа: максимум сотрудников — {max}."
            : null;
    }
}