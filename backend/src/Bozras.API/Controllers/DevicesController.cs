using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Bozras.Application.DTOs.Devices.Request;
using Bozras.Application.Interfaces.Services;

namespace Bozras.API.Controllers;

[Route("api/[controller]")]
[Authorize]
public class DevicesController : ApiControllerBase
{
    private readonly IDeviceService _deviceService;

    public DevicesController(IDeviceService deviceService)
    {
        _deviceService = deviceService;
    }

    [HttpPut("fcm-token")]
    public async Task<IActionResult> SetFcmToken([FromBody] RegisterFcmTokenRequest request, CancellationToken ct)
    {
        return ToActionResult(await _deviceService.SetFcmTokenAsync(CurrentUserId, request, ct));
    }

    [HttpDelete("fcm-token")]
    public async Task<IActionResult> ClearFcmToken(CancellationToken ct)
    {
        return ToActionResult(await _deviceService.ClearFcmTokenAsync(CurrentUserId, ct));
    }
}