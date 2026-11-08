using Bozras.Application.Common;
using Bozras.Application.DTOs.Visits.Request;
using Bozras.Application.DTOs.Visits.Response;

namespace Bozras.Application.Interfaces.Services;

public interface IVisitService
{
    Task<Result<PagedResult<VisitResponse>>> GetPagedAsync(
        VisitQueryRequest request, CurrentUser caller, CancellationToken ct = default);

    Task<Result<VisitResponse>> GetByIdAsync(Guid id, CurrentUser caller, CancellationToken ct = default);

    Task<Result<VisitResponse>> CreateAsync(
        CreateVisitRequest request, CurrentUser caller, CancellationToken ct = default);
}