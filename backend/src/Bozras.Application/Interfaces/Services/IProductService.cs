using Bozras.Application.Common;
using Bozras.Application.DTOs.Products.Request;
using Bozras.Application.DTOs.Products.Response;

namespace Bozras.Application.Interfaces.Services;

public interface IProductService
{
    Task<Result<IReadOnlyList<ProductResponse>>> GetActiveAsync(CancellationToken ct = default);

    Task<Result<PagedResult<ProductResponse>>> GetPagedAsync(ProductQueryRequest request, CancellationToken ct = default);

    Task<Result<ProductResponse>> GetByIdAsync(Guid id, CancellationToken ct = default);

    Task<Result<ProductResponse>> CreateAsync(CreateProductRequest request, CancellationToken ct = default);

    Task<Result<ProductResponse>> UpdateAsync(Guid id, UpdateProductRequest request, CancellationToken ct = default);
}