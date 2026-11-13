using Bozras.Application.Common;
using Bozras.Application.DTOs.Settings.Request;
using Bozras.Application.DTOs.Settings.Response;

namespace Bozras.Application.Interfaces.Services;

public interface ISettingService
{
    Task<Result<SettingsResponse>> GetAsync(CancellationToken ct = default);

    Task<Result<SettingsResponse>> UpdateAsync(UpdateSettingsRequest request, CancellationToken ct = default);
}