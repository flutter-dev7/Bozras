using Microsoft.EntityFrameworkCore;
using Bozras.Application.Common;
using Bozras.Application.Interfaces.Repositories;
using Bozras.Domain.Entities;
using Bozras.Domain.Enums;
using Bozras.Infrastructure.Persistence.Data;

namespace Bozras.Infrastructure.Repositories;

public class SupplierRepository : ISupplierRepository
{
    private readonly AppDbContext _context;

    public SupplierRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<(List<Supplier> Items, int TotalCount)> GetPagedAsync(
        string? search, bool? isActive, int page, int pageSize, CancellationToken ct = default)
    {
        var query = _context.Suppliers
            .AsNoTracking()
            .Include(s => s.Plan)
            .Include(s => s.ServiceAreas)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            var pattern = $"%{search.Trim()}%";
            query = query.Where(s =>
                EF.Functions.ILike(s.Name, pattern) ||
                EF.Functions.ILike(s.Code, pattern) ||
                (s.Phone != null && EF.Functions.ILike(s.Phone, pattern)));
        }

        if (isActive.HasValue)
            query = query.Where(s => s.IsActive == isActive.Value);

        var totalCount = await query.CountAsync(ct);

        var items = await query
            .OrderBy(s => s.Name)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(ct);

        return (items, totalCount);
    }

    public Task<Supplier?> GetByIdAsync(Guid id, CancellationToken ct = default) =>
        _context.Suppliers
            .Include(s => s.Plan)
            .Include(s => s.ServiceAreas)
            .FirstOrDefaultAsync(s => s.Id == id, ct);

    public Task<bool> CodeExistsAsync(string code, CancellationToken ct = default) =>
        _context.Suppliers.AnyAsync(s => s.Code == code, ct);

    public async Task<Dictionary<Guid, SupplierStats>> GetStatsAsync(
        IReadOnlyCollection<Guid> ids, CancellationToken ct = default)
    {
        if (ids.Count == 0)
            return new Dictionary<Guid, SupplierStats>();

        var shops = await _context.Shops
            .IgnoreQueryFilters()
            .Where(s => ids.Contains(s.SupplierId))
            .GroupBy(s => s.SupplierId)
            .Select(g => new { SupplierId = g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.SupplierId, x => x.Count, ct);

        var staff = await _context.Users
            .Where(u => u.SupplierId != null && ids.Contains(u.SupplierId.Value))
            .GroupBy(u => u.SupplierId!.Value)
            .Select(g => new { SupplierId = g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.SupplierId, x => x.Count, ct);

        var admins = await _context.Users
            .Where(u => u.Role == UserRole.Admin && u.SupplierId != null && ids.Contains(u.SupplierId.Value))
            .OrderBy(u => u.CreatedAt)
            .Select(u => new { SupplierId = u.SupplierId!.Value, u.Email })
            .ToListAsync(ct);

        var firstAdmin = admins
            .GroupBy(a => a.SupplierId)
            .ToDictionary(g => g.Key, g => g.First().Email);

        return ids.ToDictionary(
            id => id,
            id => new SupplierStats(
                shops.GetValueOrDefault(id),
                staff.GetValueOrDefault(id),
                firstAdmin.GetValueOrDefault(id)));
    }

    public Task<List<SubscriptionPayment>> GetPaymentsAsync(Guid supplierId, CancellationToken ct = default) =>
        _context.SubscriptionPayments
            .AsNoTracking()
            .Include(p => p.Plan)
            .Where(p => p.SupplierId == supplierId)
            .OrderByDescending(p => p.CreatedAt)
            .ToListAsync(ct);

    public async Task AddAsync(Supplier supplier, CancellationToken ct = default)
    {
        await _context.Suppliers.AddAsync(supplier, ct);
    }

    public async Task AddPaymentAsync(SubscriptionPayment payment, CancellationToken ct = default)
    {
        await _context.SubscriptionPayments.AddAsync(payment, ct);
    }
}