using Microsoft.EntityFrameworkCore;
using Bozras.Application.Interfaces.Repositories;
using Bozras.Domain.Entities;
using Bozras.Infrastructure.Persistence.Data;

namespace Bozras.Infrastructure.Repositories;

public class CategoryRepository : ICategoryRepository
{
    private readonly AppDbContext _context;

    public CategoryRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<List<(Category Category, int ProductsCount)>> GetAllWithCountsAsync(CancellationToken ct = default)
    {
        var rows = await _context.Categories
            .AsNoTracking()
            .OrderBy(c => c.Name)
            .Select(c => new { Category = c, Count = _context.Products.Count(p => p.CategoryId == c.Id) })
            .ToListAsync(ct);

        return rows.Select(r => (r.Category, r.Count)).ToList();
    }

    public Task<Category?> GetByIdAsync(Guid id, CancellationToken ct = default) =>
        _context.Categories.FirstOrDefaultAsync(c => c.Id == id, ct);

    public Task<bool> ExistsByNameAsync(string name, Guid? excludeId, CancellationToken ct = default)
    {
        var lowered = name.ToLower();

        return _context.Categories.AnyAsync(
            c => c.Name.ToLower() == lowered && (excludeId == null || c.Id != excludeId), ct);
    }

    public Task<bool> HasProductsAsync(Guid id, CancellationToken ct = default) =>
        _context.Products.AnyAsync(p => p.CategoryId == id, ct);

    public async Task AddAsync(Category category, CancellationToken ct = default)
    {
        await _context.Categories.AddAsync(category, ct);
    }

    public void Remove(Category category)
    {
        _context.Categories.Remove(category);
    }
}