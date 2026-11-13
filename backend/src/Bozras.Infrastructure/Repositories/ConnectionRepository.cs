using Microsoft.EntityFrameworkCore;
using Bozras.Application.Common;
using Bozras.Application.Interfaces.Repositories;
using Bozras.Domain.Entities;
using Bozras.Domain.Enums;
using Bozras.Infrastructure.Persistence.Data;

namespace Bozras.Infrastructure.Repositories;

public class ConnectionRepository : IConnectionRepository
{
    private readonly AppDbContext _context;

    public ConnectionRepository(AppDbContext context)
    {
        _context = context;
    }

    public Task<ShopProfile?> GetProfileAsync(Guid userId, CancellationToken ct = default) =>
        _context.ShopProfiles
            .Include(p => p.Location)
            .FirstOrDefaultAsync(p => p.UserId == userId, ct);

    public async Task AddProfileAsync(ShopProfile profile, CancellationToken ct = default)
    {
        await _context.ShopProfiles.AddAsync(profile, ct);
    }

    public Task<bool> LocationExistsAsync(Guid locationId, CancellationToken ct = default) =>
        _context.Locations.AnyAsync(l => l.Id == locationId && l.IsActive, ct);

    public async Task<List<Guid>> GetLocationChainAsync(Guid locationId, CancellationToken ct = default)
    {
        var ids = new List<Guid>();
        Guid? current = locationId;

        while (current.HasValue && ids.Count < 6)
        {
            var id = current.Value;
            ids.Add(id);

            current = await _context.Locations
                .Where(l => l.Id == id)
                .Select(l => l.ParentId)
                .FirstOrDefaultAsync(ct);
        }

        return ids;
    }

    public async Task<List<Supplier>> GetNearbySuppliersAsync(
        IReadOnlyCollection<Guid> locationIds, string? search, CancellationToken ct = default)
    {
        var now = DateTime.UtcNow;
        var graceDays = SubscriptionRules.GraceDays;

        var query = _context.Suppliers
            .AsNoTracking()
            .Where(s => s.IsActive
                        && s.SubscriptionStatus != SubscriptionStatus.Suspended
                        && (s.SubscriptionEndsAt == null || s.SubscriptionEndsAt.Value.AddDays(graceDays) > now)
                        && s.ServiceAreas.Any(a => locationIds.Contains(a.LocationId)));

        if (!string.IsNullOrWhiteSpace(search))
            query = query.Where(s => EF.Functions.ILike(s.Name, $"%{search.Trim()}%"));

        return await query.OrderBy(s => s.Name).ToListAsync(ct);
    }

    public Task<Supplier?> GetSupplierByCodeAsync(string code, CancellationToken ct = default)
    {
        var normalized = code.ToUpper();

        return _context.Suppliers
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.IsActive && s.Code.ToUpper() == normalized, ct);
    }

    public Task<List<ShopSupplierLink>> GetLinksAsync(Guid userId, CancellationToken ct = default)
    {
        var now = DateTime.UtcNow;
        var graceDays = SubscriptionRules.GraceDays;

        return _context.Shops
            .IgnoreQueryFilters()
            .AsNoTracking()
            .Where(s => s.UserId == userId)
            .Join(_context.Suppliers, s => s.SupplierId, sup => sup.Id, (s, sup) => new ShopSupplierLink(
                sup.Id,
                sup.Name,
                sup.Phone,
                sup.Description,
                sup.LogoUrl,
                sup.RequiresApproval,
                s.Status,
                sup.IsActive
                && sup.SubscriptionStatus != SubscriptionStatus.Suspended
                && (sup.SubscriptionEndsAt == null || sup.SubscriptionEndsAt.Value.AddDays(graceDays) > now)))
            .ToListAsync(ct);
    }

    public Task<Shop?> GetUserShopAsync(Guid userId, Guid supplierId, CancellationToken ct = default) =>
        _context.Shops
            .IgnoreQueryFilters()
            .FirstOrDefaultAsync(s => s.UserId == userId && s.SupplierId == supplierId, ct);

    public async Task AddShopAsync(Shop shop, CancellationToken ct = default)
    {
        await _context.Shops.AddAsync(shop, ct);
    }

    public Task<Supplier?> GetSupplierAsync(Guid id, bool withPlan, CancellationToken ct = default)
    {
        IQueryable<Supplier> query = _context.Suppliers;

        if (withPlan)
            query = query.Include(s => s.Plan);

        return query.FirstOrDefaultAsync(s => s.Id == id, ct);
    }

    public Task<bool> CodeExistsAsync(string code, CancellationToken ct = default) =>
        _context.Suppliers.AnyAsync(s => s.Code == code, ct);
}