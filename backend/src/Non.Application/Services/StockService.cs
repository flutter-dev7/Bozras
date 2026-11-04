using Non.Application.Common;
using Non.Application.DTOs.Stock.Request;
using Non.Application.DTOs.Stock.Response;
using Non.Application.Interfaces.Repositories;
using Non.Application.Interfaces.Services;
using Non.Domain.Entities;
using Non.Domain.Enums;

namespace Non.Application.Services;

public class StockService : IStockService
{
    private readonly IStockRepository _stockRepository;
    private readonly IProductRepository _productRepository;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ICacheService _cacheService;

    public StockService(
        IStockRepository stockRepository,
        IProductRepository productRepository,
        IUnitOfWork unitOfWork,
        ICacheService cacheService)
    {
        _stockRepository = stockRepository;
        _productRepository = productRepository;
        _unitOfWork = unitOfWork;
        _cacheService = cacheService;
    }

    public async Task<Result<StockMovementResponse>> ReceiveAsync(
        ReceiveStockRequest request, Guid userId, CancellationToken ct = default)
    {
        var product = await FindProductAsync(request.ProductId, ct);
        if (product is null)
            return Result<StockMovementResponse>.Failure("Товар не найден.", ErrorType.NotFound);

        await using var transaction = await _unitOfWork.BeginTransactionAsync(ct);

        if (!await _stockRepository.IncreaseAsync(product.Id, request.Quantity, ct))
            return Result<StockMovementResponse>.Failure("Товар не найден.", ErrorType.NotFound);

        var movement = await RecordAsync(
            product.Id, StockMovementType.Receipt, request.Quantity, null, request.Comment, userId, ct);

        await _unitOfWork.SaveChangesAsync(ct);
        await transaction.CommitAsync(ct);

        await InvalidateCacheAsync([product.Id]);

        var response = ToResponse(movement);
        response.ProductName = product.Name;

        return Result<StockMovementResponse>.Success(response);
    }

    public async Task<Result<StockMovementResponse>> WriteOffAsync(
        WriteOffStockRequest request, Guid userId, CancellationToken ct = default)
    {
        var product = await FindProductAsync(request.ProductId, ct);
        if (product is null)
            return Result<StockMovementResponse>.Failure("Товар не найден.", ErrorType.NotFound);

        await using var transaction = await _unitOfWork.BeginTransactionAsync(ct);

        if (!await _stockRepository.TryDecreaseAsync(product.Id, request.Quantity, ct))
        {
            var balance = await _stockRepository.GetBalanceAsync(product.Id, ct);

            return Result<StockMovementResponse>.Failure(
                $"Нельзя списать {request.Quantity} {product.Unit}: на складе {balance} {product.Unit}.");
        }

        var movement = await RecordAsync(
            product.Id, StockMovementType.WriteOff, -request.Quantity, null, request.Comment, userId, ct);

        await _unitOfWork.SaveChangesAsync(ct);
        await transaction.CommitAsync(ct);

        await InvalidateCacheAsync([product.Id]);

        var response = ToResponse(movement);
        response.ProductName = product.Name;

        return Result<StockMovementResponse>.Success(response);
    }

    public async Task<Result<PagedResult<StockMovementResponse>>> GetMovementsAsync(
        StockMovementQueryRequest request, CancellationToken ct = default)
    {
        var page = Math.Max(request.Page, 1);
        var pageSize = Math.Clamp(request.PageSize, 1, 100);

        var (items, totalCount) = await _stockRepository.GetMovementsPagedAsync(
            request.ProductId, page, pageSize, ct);

        return Result<PagedResult<StockMovementResponse>>.Success(new PagedResult<StockMovementResponse>
        {
            Items = items.Select(ToResponse).ToList(),
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize
        });
    }

    public async Task<Result<bool>> ApplyOrderChangeAsync(
        IEnumerable<(Guid ProductId, int StockDelta)> changes, Guid orderId, Guid userId, CancellationToken ct = default)
    {
        foreach (var (productId, delta) in changes.Where(c => c.StockDelta != 0).OrderBy(c => c.ProductId))
        {
            if (delta < 0)
            {
                if (!await _stockRepository.TryDecreaseAsync(productId, -delta, ct))
                    return await NotEnoughAsync(productId, ct);
            }
            else if (!await _stockRepository.IncreaseAsync(productId, delta, ct))
            {
                return Result<bool>.Failure("Товар не найден.", ErrorType.NotFound);
            }

            await RecordAsync(
                productId,
                delta < 0 ? StockMovementType.OrderReserve : StockMovementType.OrderRelease,
                delta,
                orderId,
                null,
                userId,
                ct);
        }

        return Result<bool>.Success(true);
    }

    public async Task InvalidateCacheAsync(IEnumerable<Guid> productIds)
    {
        await _cacheService.RemoveAsync(CacheKeys.ActiveProducts);

        foreach (var id in productIds.Distinct())
            await _cacheService.RemoveAsync(CacheKeys.Product(id));
    }

    private async Task<Product?> FindProductAsync(Guid id, CancellationToken ct) =>
        (await _productRepository.GetByIdsAsync([id], ct)).FirstOrDefault();

    private async Task<Result<bool>> NotEnoughAsync(Guid productId, CancellationToken ct)
    {
        var product = await FindProductAsync(productId, ct);
        var balance = await _stockRepository.GetBalanceAsync(productId, ct);

        return Result<bool>.Failure(
            $"Недостаточно товара «{product?.Name}»: осталось {balance} {product?.Unit}.");
    }

    private async Task<StockMovement> RecordAsync(
        Guid productId, StockMovementType type, int signedQuantity,
        Guid? orderId, string? comment, Guid? userId, CancellationToken ct)
    {
        var movement = new StockMovement
        {
            ProductId = productId,
            Type = type,
            Quantity = signedQuantity,
            BalanceAfter = await _stockRepository.GetBalanceAsync(productId, ct),
            OrderId = orderId,
            Comment = string.IsNullOrWhiteSpace(comment) ? null : comment.Trim(),
            CreatedByUserId = userId
        };

        await _stockRepository.AddMovementAsync(movement, ct);

        return movement;
    }

    private static StockMovementResponse ToResponse(StockMovement movement) => new()
    {
        Id = movement.Id,
        ProductId = movement.ProductId,
        ProductName = movement.Product?.Name ?? string.Empty,
        Type = movement.Type.ToString(),
        Quantity = movement.Quantity,
        BalanceAfter = movement.BalanceAfter,
        OrderId = movement.OrderId,
        Comment = movement.Comment,
        CreatedByName = movement.CreatedByUser?.FullName,
        CreatedAt = movement.CreatedAt
    };
}