using Bozras.Application.Common;
using Bozras.Application.DTOs.Plans.Request;
using Bozras.Application.DTOs.Plans.Response;

namespace Bozras.Application.Interfaces.Services;

public interface IPlanService
{
    Task<Result<List<PlanResponse>>> GetAllAsync(CancellationToken ct = default);

    Task<Result<PlanResponse>> CreateAsync(SavePlanRequest request, CancellationToken ct = default);

    Task<Result<PlanResponse>> UpdateAsync(Guid id, SavePlanRequest request, CancellationToken ct = default);
}