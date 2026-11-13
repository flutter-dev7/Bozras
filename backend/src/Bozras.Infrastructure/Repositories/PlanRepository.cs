using Microsoft.EntityFrameworkCore;
using Bozras.Application.Interfaces.Repositories;
using Bozras.Domain.Entities;
using Bozras.Infrastructure.Persistence.Data;

namespace Bozras.Infrastructure.Repositories;

public class PlanRepository : IPlanRepository
{
    private readonly AppDbContext _context;

    public PlanRepository(AppDbContext context)
    {
        _context = context;
    }

    public Task<List<Plan>> GetAllAsync(CancellationToken ct = default) =>
        _context.Plans.AsNoTracking().OrderBy(p => p.PricePerMonth).ThenBy(p => p.Name).ToListAsync(ct);

    public Task<Plan?> GetByIdAsync(Guid id, CancellationToken ct = default) =>
        _context.Plans.FirstOrDefaultAsync(p => p.Id == id, ct);

    public Task<bool> NameExistsAsync(string name, Guid? excludeId, CancellationToken ct = default) =>
        _context.Plans.AnyAsync(
            p => p.Name.ToLower() == name.ToLower() && (excludeId == null || p.Id != excludeId), ct);

    public async Task AddAsync(Plan plan, CancellationToken ct = default)
    {
        await _context.Plans.AddAsync(plan, ct);
    }
}