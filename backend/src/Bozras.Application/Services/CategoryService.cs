using Bozras.Application.Common;
using Bozras.Application.DTOs.Categories.Request;
using Bozras.Application.DTOs.Categories.Response;
using Bozras.Application.Interfaces.Repositories;
using Bozras.Application.Interfaces.Services;
using Bozras.Domain.Entities;
using Bozras.Domain.Enums;

namespace Bozras.Application.Services;

public class CategoryService : ICategoryService
{
    private readonly ICategoryRepository _categoryRepository;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ICacheService _cacheService;
    private readonly ITenantContext _tenant;

    public CategoryService(
        ICategoryRepository categoryRepository,
        IUnitOfWork unitOfWork,
        ICacheService cacheService,
        ITenantContext tenant)
    {
        _categoryRepository = categoryRepository;
        _unitOfWork = unitOfWork;
        _cacheService = cacheService;
        _tenant = tenant;
    }

    public async Task<Result<IReadOnlyList<CategoryResponse>>> GetAllAsync(CancellationToken ct = default)
    {
        var rows = await _categoryRepository.GetAllWithCountsAsync(ct);

        IReadOnlyList<CategoryResponse> list = rows
            .Select(r => ToResponse(r.Category, r.ProductsCount))
            .ToList();

        return Result<IReadOnlyList<CategoryResponse>>.Success(list);
    }

    public async Task<Result<CategoryResponse>> CreateAsync(SaveCategoryRequest request, CancellationToken ct = default)
    {
        var name = request.Name.Trim();

        if (await _categoryRepository.ExistsByNameAsync(name, null, ct))
            return Result<CategoryResponse>.Failure("Категория с таким названием уже существует.", ErrorType.Conflict);

        var category = new Category { Name = name };

        await _categoryRepository.AddAsync(category, ct);
        await _unitOfWork.SaveChangesAsync(ct);

        return Result<CategoryResponse>.Success(ToResponse(category, 0));
    }

    public async Task<Result<CategoryResponse>> UpdateAsync(
        Guid id, SaveCategoryRequest request, CancellationToken ct = default)
    {
        var category = await _categoryRepository.GetByIdAsync(id, ct);
        if (category is null)
            return Result<CategoryResponse>.Failure("Категория не найдена.", ErrorType.NotFound);

        var name = request.Name.Trim();

        if (await _categoryRepository.ExistsByNameAsync(name, id, ct))
            return Result<CategoryResponse>.Failure("Категория с таким названием уже существует.", ErrorType.Conflict);

        category.Name = name;
        await _unitOfWork.SaveChangesAsync(ct);

        await _cacheService.RemoveAsync(CacheKeys.ActiveProducts(_tenant.RequireSupplierId()));

        return Result<CategoryResponse>.Success(ToResponse(category, 0));
    }

    public async Task<Result<bool>> DeleteAsync(Guid id, CancellationToken ct = default)
    {
        var category = await _categoryRepository.GetByIdAsync(id, ct);
        if (category is null)
            return Result<bool>.Failure("Категория не найдена.", ErrorType.NotFound);

        if (await _categoryRepository.HasProductsAsync(id, ct))
            return Result<bool>.Failure("В категории есть товары. Сначала переместите их в другую.", ErrorType.Conflict);

        _categoryRepository.Remove(category);
        await _unitOfWork.SaveChangesAsync(ct);

        return Result<bool>.Success(true);
    }

    private static CategoryResponse ToResponse(Category category, int productsCount) => new()
    {
        Id = category.Id,
        Name = category.Name,
        ProductsCount = productsCount
    };
}