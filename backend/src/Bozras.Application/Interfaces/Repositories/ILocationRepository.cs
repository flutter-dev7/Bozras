using Bozras.Domain.Entities;

namespace Bozras.Application.Interfaces.Repositories;

public interface ILocationRepository
{
    Task<List<Location>> GetAllAsync(CancellationToken ct = default);

    Task<Location?> GetByIdAsync(Guid id, CancellationToken ct = default);

    Task<int> CountExistingAsync(IReadOnlyCollection<Guid> ids, CancellationToken ct = default);

    Task<bool> NameExistsAsync(Guid? parentId, string name, Guid? excludeId, CancellationToken ct = default);

    Task<bool> HasChildrenAsync(Guid id, CancellationToken ct = default);

    Task<bool> IsUsedByServiceAreasAsync(Guid id, CancellationToken ct = default);

    Task AddAsync(Location location, CancellationToken ct = default);

    void Remove(Location location);
}