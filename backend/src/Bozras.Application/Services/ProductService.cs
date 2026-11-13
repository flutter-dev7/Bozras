using Bozras.Application.Common;
using Bozras.Application.DTOs.Products.Request;
using Bozras.Application.DTOs.Products.Response;
using Bozras.Application.Interfaces.Repositories;
using Bozras.Application.Interfaces.Services;
using Bozras.Domain.Entities;
using Bozras.Domain.Enums;

namespace Bozras.Application.Services;

public class ProductService : IProductService
{
    private static readonly TimeSpan CacheDuration = TimeSpan.FromMinutes(30);

    private readonly IProductRepository _productRepository;
    private readonly ICategoryRepository _categoryRepository;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ICacheService _cacheService;
    private readonly ITenantContext _tenant;

    public ProductService(
        IProductRepository productRepository,
        ICategoryRepository categoryRepository,
        IUnitOfWork unitOfWork,
        ICacheService cacheService,
        ITenantContext tenant)
    {
        _productRepository = productRepository;
        _categoryRepository = categoryRepository;
        _unitOfWork = unitOfWork;
        _cacheService = cacheService;
        _tenant = tenant;
    }

    public async Task<Result<IReadOnlyList<ProductResponse>>> GetActiveAsync(CancellationToken ct = default)
    {
        var products = await _cacheService.GetOrCreateAsync<IReadOnlyList<ProductResponse>>(
            CacheKeys.ActiveProducts(_tenant.RequireSupplierId()),
            async () => (await _productRepository.GetActiveAsync(ct)).Select(ToResponse).ToList(),
            CacheDuration);

        return Result<IReadOnlyList<ProductResponse>>.Success(products);
    }

    public async Task<Result<PagedResult<ProductResponse>>> GetPagedAsync(
        ProductQueryRequest request, CancellationToken ct = default)
    {
        var page = Math.Max(request.Page, 1);
        var pageSize = Math.Clamp(request.PageSize, 1, 100);

        var (items, totalCount) = await _productRepository.GetPagedAsync(
            request.Search, request.IsActive, request.CategoryId, page, pageSize, ct);

        var result = new PagedResult<ProductResponse>
        {
            Items = items.Select(ToResponse).ToList(),
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize
        };

        return Result<PagedResult<ProductResponse>>.Success(result);
    }

    public async Task<Result<ProductResponse>> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        var key = CacheKeys.Product(_tenant.RequireSupplierId(), id);

        var cached = await _cacheService.GetAsync<ProductResponse>(key);
        if (cached is not null)
            return Result<ProductResponse>.Success(cached);

        var product = await _productRepository.GetByIdAsync(id, ct);
        if (product is null)
            return Result<ProductResponse>.Failure("Продукт не найден.", ErrorType.NotFound);

        var response = ToResponse(product);
        await _cacheService.SetAsync(key, response, CacheDuration);

        return Result<ProductResponse>.Success(response);
    }

    public async Task<Result<ProductResponse>> CreateAsync(CreateProductRequest request, CancellationToken ct = default)
    {
        var name = request.Name.Trim();

        if (await _productRepository.ExistsByNameAsync(name, null, ct))
            return Result<ProductResponse>.Failure("Продукт с таким названием уже существует.", ErrorType.Conflict);

        Category? category = null;
        if (request.CategoryId.HasValue)
        {
            category = await _categoryRepository.GetByIdAsync(request.CategoryId.Value, ct);
            if (category is null)
                return Result<ProductResponse>.Failure("Категория не найдена.", ErrorType.NotFound);
        }

        var product = new Product
        {
            Name = name,
            WeightInGrams = request.WeightInGrams,
            Price = request.Price,
            ImageUrl = request.ImageUrl,
            Unit = request.Unit.Trim(),
            CategoryId = category?.Id,
            Category = category,
            IsActive = true
        };

        await _productRepository.AddAsync(product, ct);
        await _unitOfWork.SaveChangesAsync(ct);

        await _cacheService.RemoveAsync(CacheKeys.ActiveProducts(_tenant.RequireSupplierId()));

        return Result<ProductResponse>.Success(ToResponse(product));
    }

    public async Task<Result<ProductResponse>> UpdateAsync(
        Guid id, UpdateProductRequest request, CancellationToken ct = default)
    {
        var product = await _productRepository.GetByIdAsync(id, ct);
        if (product is null)
            return Result<ProductResponse>.Failure("Продукт не найден.", ErrorType.NotFound);

        var name = request.Name.Trim();

        if (await _productRepository.ExistsByNameAsync(name, id, ct))
            return Result<ProductResponse>.Failure("Продукт с таким названием уже существует.", ErrorType.Conflict);

        Category? category = null;
        if (request.CategoryId.HasValue)
        {
            category = await _categoryRepository.GetByIdAsync(request.CategoryId.Value, ct);
            if (category is null)
                return Result<ProductResponse>.Failure("Категория не найдена.", ErrorType.NotFound);
        }

        product.Name = name;
        product.WeightInGrams = request.WeightInGrams;
        product.Price = request.Price;
        product.ImageUrl = request.ImageUrl;
        product.Unit = request.Unit.Trim();
        product.CategoryId = category?.Id;
        product.Category = category;
        product.IsActive = request.IsActive;

        await _unitOfWork.SaveChangesAsync(ct);

        await _cacheService.RemoveAsync(CacheKeys.ActiveProducts(_tenant.RequireSupplierId()));
        await _cacheService.RemoveAsync(CacheKeys.Product(_tenant.RequireSupplierId(), id));

        return Result<ProductResponse>.Success(ToResponse(product));
    }

    private static ProductResponse ToResponse(Product product) => new()
    {
        Id = product.Id,
        Name = product.Name,
        WeightInGrams = product.WeightInGrams,
        Price = product.Price,
        ImageUrl = product.ImageUrl,
        IsActive = product.IsActive,
        CategoryId = product.CategoryId,
        CategoryName = product.Category?.Name,
        Unit = product.Unit,
        StockQuantity = product.StockQuantity
    };
}