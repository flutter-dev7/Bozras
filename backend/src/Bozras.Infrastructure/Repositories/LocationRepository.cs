using Microsoft.EntityFrameworkCore;
using Bozras.Application.Interfaces.Repositories;
using Bozras.Domain.Entities;
using Bozras.Infrastructure.Persistence.Data;

namespace Bozras.Infrastructure.Repositories;

public class LocationRepository : ILocationRepository
{
    private readonly AppDbContext _context;

    public LocationRepository(AppDbContext context)
    {
        _context = context;
    }

    public Task<List<Location>> GetAllAsync(CancellationToken ct = default) =>
        _context.Locations.AsNoTracking().OrderBy(l => l.Name).ToListAsync(ct);

    public Task<Location?> GetByIdAsync(Guid id, CancellationToken ct = default) =>
        _context.Locations.FirstOrDefaultAsync(l => l.Id == id, ct);

    public Task<int> CountExistingAsync(IReadOnlyCollection<Guid> ids, CancellationToken ct = default) =>
        _context.Locations.CountAsync(l => ids.Contains(l.Id), ct);

    public Task<bool> NameExistsAsync(Guid? parentId, string name, Guid? excludeId, CancellationToken ct = default) =>
        _context.Locations.AnyAsync(
            l => l.ParentId == parentId
                 && l.Name.ToLower() == name.ToLower()
                 && (excludeId == null || l.Id != excludeId), ct);

    public Task<bool> HasChildrenAsync(Guid id, CancellationToken ct = default) =>
        _context.Locations.AnyAsync(l => l.ParentId == id, ct);

    public Task<bool> IsUsedByServiceAreasAsync(Guid id, CancellationToken ct = default) =>
        _context.ServiceAreas.AnyAsync(a => a.LocationId == id, ct);

    public async Task AddAsync(Location location, CancellationToken ct = default)
    {
        await _context.Locations.AddAsync(location, ct);
    }

    public void Remove(Location location)
    {
        _context.Locations.Remove(location);
    }
}