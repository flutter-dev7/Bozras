using Microsoft.EntityFrameworkCore;
using Non.Application.Interfaces.Repositories;
using Non.Domain.Entities;
using Non.Infrastructure.Persistence.Data;

namespace Non.Infrastructure.Repositories;

public class StockRepository : IStockRepository
{
    private readonly AppDbContext _context;

    public StockRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<bool> TryDecreaseAsync(Guid productId, int quantity, CancellationToken ct = default)
    {
        var affected = await _context.Products
            .Where(p => p.Id == productId && p.StockQuantity >= quantity)
            .ExecuteUpdateAsync(s => s.SetProperty(p => p.StockQuantity, p => p.StockQuantity - quantity), ct);

        return affected == 1;
    }

    public async Task<bool> IncreaseAsync(Guid productId, int quantity, CancellationToken ct = default)
    {
        var affected = await _context.Products
            .Where(p => p.Id == productId)
            .ExecuteUpdateAsync(s => s.SetProperty(p => p.StockQuantity, p => p.StockQuantity + quantity), ct);

        return affected == 1;
    }

    public Task<int> GetBalanceAsync(Guid productId, CancellationToken ct = default) =>
        _context.Products
            .AsNoTracking()
            .Where(p => p.Id == productId)
            .Select(p => p.StockQuantity)
            .FirstOrDefaultAsync(ct);

    public async Task AddMovementAsync(StockMovement movement, CancellationToken ct = default)
    {
        await _context.StockMovements.AddAsync(movement, ct);
    }

    public async Task<(List<StockMovement> Items, int TotalCount)> GetMovementsPagedAsync(
        Guid? productId, int page, int pageSize, CancellationToken ct = default)
    {
        var query = _context.StockMovements
            .AsNoTracking()
            .Include(m => m.Product)
            .Include(m => m.CreatedByUser)
            .AsQueryable();

        if (productId.HasValue)
            query = query.Where(m => m.ProductId == productId.Value);

        var totalCount = await query.CountAsync(ct);

        var items = await query
            .OrderByDescending(m => m.CreatedAt)
            .ThenByDescending(m => m.Id)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(ct);

        return (items, totalCount);
    }
}