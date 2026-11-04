using Non.Application.Common;
using Non.Application.DTOs.Categories.Request;
using Non.Application.DTOs.Categories.Response;

namespace Non.Application.Interfaces.Services;

public interface ICategoryService
{
    Task<Result<IReadOnlyList<CategoryResponse>>> GetAllAsync(CancellationToken ct = default);
    Task<Result<CategoryResponse>> CreateAsync(SaveCategoryRequest request, CancellationToken ct = default);
    Task<Result<CategoryResponse>> UpdateAsync(Guid id, SaveCategoryRequest request, CancellationToken ct = default);
    Task<Result<bool>> DeleteAsync(Guid id, CancellationToken ct = default);
}