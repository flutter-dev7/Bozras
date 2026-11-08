using Bozras.Application.Common;
using Bozras.Application.DTOs.Stock.Request;
using Bozras.Application.DTOs.Stock.Response;

namespace Bozras.Application.Interfaces.Services;

public interface IStockService
{
    Task<Result<StockMovementResponse>> ReceiveAsync(
        ReceiveStockRequest request, Guid userId, CancellationToken ct = default);

    Task<Result<StockMovementResponse>> WriteOffAsync(
        WriteOffStockRequest request, Guid userId, CancellationToken ct = default);

    Task<Result<PagedResult<StockMovementResponse>>> GetMovementsAsync(
        StockMovementQueryRequest request, CancellationToken ct = default);

    Task<Result<bool>> ApplyOrderChangeAsync(
        IEnumerable<(Guid ProductId, int StockDelta)> changes, Guid orderId, Guid userId, CancellationToken ct = default);

    Task InvalidateCacheAsync(IEnumerable<Guid> productIds);
}