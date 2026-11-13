using Bozras.Domain.Entities;

namespace Bozras.Application.Interfaces.Repositories;

public interface IPlanRepository
{
    Task<List<Plan>> GetAllAsync(CancellationToken ct = default);

    Task<Plan?> GetByIdAsync(Guid id, CancellationToken ct = default);

    Task<bool> NameExistsAsync(string name, Guid? excludeId, CancellationToken ct = default);

    Task AddAsync(Plan plan, CancellationToken ct = default);
}