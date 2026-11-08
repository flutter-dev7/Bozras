using System.Globalization;
using Bozras.Application.Common;
using Bozras.Application.DTOs.Settings.Request;
using Bozras.Application.DTOs.Settings.Response;
using Bozras.Application.Interfaces.Repositories;
using Bozras.Application.Interfaces.Services;
using Bozras.Domain.Constants;

namespace Bozras.Application.Services;

public class SettingService : ISettingService
{
    private readonly ISettingRepository _settingRepository;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ICacheService _cacheService;
    private readonly ITenantContext _tenant;

    public SettingService(
        ISettingRepository settingRepository,
        IUnitOfWork unitOfWork,
        ICacheService cacheService,
        ITenantContext tenant)
    {
        _settingRepository = settingRepository;
        _unitOfWork = unitOfWork;
        _cacheService = cacheService;
        _tenant = tenant;
    }

    public async Task<Result<SettingsResponse>> GetAsync(CancellationToken ct = default)
    {
        var cutoff = await _settingRepository.GetValueAsync(SettingKeys.OrderCutoffTime, ct)
                     ?? SettingDefaults.OrderCutoffTime;

        return Result<SettingsResponse>.Success(new SettingsResponse { OrderCutoffTime = cutoff });
    }

    public async Task<Result<SettingsResponse>> UpdateAsync(UpdateSettingsRequest request, CancellationToken ct = default)
    {
        if (!TimeOnly.TryParseExact(request.OrderCutoffTime, "HH:mm", CultureInfo.InvariantCulture,
                DateTimeStyles.None, out var cutoff))
        {
            return Result<SettingsResponse>.Failure("Время должно быть в формате HH:mm, например 18:00.");
        }

        var value = cutoff.ToString("HH:mm", CultureInfo.InvariantCulture);

        await _settingRepository.SetValueAsync(SettingKeys.OrderCutoffTime, value, ct);
        await _unitOfWork.SaveChangesAsync(ct);
        await _cacheService.RemoveAsync(CacheKeys.OrderCutoffTime(_tenant.RequireSupplierId()));

        return Result<SettingsResponse>.Success(new SettingsResponse { OrderCutoffTime = value });
    }
}