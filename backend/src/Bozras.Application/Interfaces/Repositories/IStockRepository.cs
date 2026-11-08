using Bozras.Domain.Entities;

namespace Bozras.Application.Interfaces.Repositories;

public interface IStockRepository
{
    Task<bool> TryDecreaseAsync(Guid productId, int quantity, CancellationToken ct = default);
    Task<bool> IncreaseAsync(Guid productId, int quantity, CancellationToken ct = default);
    Task<int> GetBalanceAsync(Guid productId, CancellationToken ct = default);
    Task AddMovementAsync(StockMovement movement, CancellationToken ct = default);
    Task<(List<StockMovement> Items, int TotalCount)> GetMovementsPagedAsync(
        Guid? productId, int page, int pageSize, CancellationToken ct = default);
}