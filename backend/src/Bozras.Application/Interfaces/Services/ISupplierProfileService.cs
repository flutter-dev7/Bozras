using Bozras.Application.Common;
using Bozras.Application.DTOs.Connections.Request;
using Bozras.Application.DTOs.Connections.Response;

namespace Bozras.Application.Interfaces.Services;

public interface ISupplierProfileService
{
    Task<Result<SupplierProfileResponse>> GetAsync(CancellationToken ct = default);
    Task<Result<SupplierProfileResponse>> UpdateAsync(UpdateSupplierProfileRequest request, CancellationToken ct = default);
    Task<Result<SupplierProfileResponse>> RegenerateCodeAsync(CancellationToken ct = default);
}