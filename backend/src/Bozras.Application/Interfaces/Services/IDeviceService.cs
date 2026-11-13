using Bozras.Application.Common;
using Bozras.Application.DTOs.Devices.Request;

namespace Bozras.Application.Interfaces.Services;

public interface IDeviceService
{
    Task<Result> SetFcmTokenAsync(Guid userId, RegisterFcmTokenRequest request, CancellationToken ct = default);

    Task<Result> ClearFcmTokenAsync(Guid userId, CancellationToken ct = default);
}