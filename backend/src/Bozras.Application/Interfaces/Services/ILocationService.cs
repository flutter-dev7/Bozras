using Bozras.Application.Common;
using Bozras.Application.DTOs.Locations.Request;
using Bozras.Application.DTOs.Locations.Response;

namespace Bozras.Application.Interfaces.Services;

public interface ILocationService
{
    Task<Result<List<LocationResponse>>> GetAllAsync(CancellationToken ct = default);

    Task<Result<LocationResponse>> CreateAsync(SaveLocationRequest request, CancellationToken ct = default);

    Task<Result<LocationResponse>> UpdateAsync(
        Guid id, SaveLocationRequest request, CancellationToken ct = default);

    Task<Result<bool>> DeleteAsync(Guid id, CancellationToken ct = default);
}