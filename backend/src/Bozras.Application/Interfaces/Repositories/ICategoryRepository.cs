using Bozras.Domain.Entities;

namespace Bozras.Application.Interfaces.Repositories;

public interface ICategoryRepository
{
    Task<List<(Category Category, int ProductsCount)>> GetAllWithCountsAsync(CancellationToken ct = default);
    Task<Category?> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<bool> ExistsByNameAsync(string name, Guid? excludeId, CancellationToken ct = default);
    Task<bool> HasProductsAsync(Guid id, CancellationToken ct = default);
    Task AddAsync(Category category, CancellationToken ct = default);
    void Remove(Category category);
}