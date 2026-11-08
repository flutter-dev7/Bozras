using Microsoft.EntityFrameworkCore;
using Bozras.Application.Interfaces.Services;
using Bozras.Domain.Enums;
using Bozras.Infrastructure.Persistence.Data;

namespace Bozras.Infrastructure.Tenancy;

public class TenantAccessService : ITenantAccessService
{
    private readonly AppDbContext _context;

    public TenantAccessService(AppDbContext context)
    {
        _context = context;
    }

    public Task<bool> SupplierExistsAsync(Guid supplierId, CancellationToken ct = default) =>
        _context.Suppliers.AnyAsync(s => s.Id == supplierId, ct);

    public Task<bool> IsSupplierAvailableAsync(Guid supplierId, CancellationToken ct = default) =>
        _context.Suppliers.AnyAsync(
            s => s.Id == supplierId && s.IsActive && s.SubscriptionStatus != SubscriptionStatus.Suspended, ct);

    public Task<bool> IsShopConnectedAsync(Guid userId, Guid supplierId, CancellationToken ct = default) =>
        _context.Shops
            .IgnoreQueryFilters()
            .AnyAsync(s => s.UserId == userId
                           && s.SupplierId == supplierId
                           && s.Status == ShopConnectionStatus.Active, ct);
}