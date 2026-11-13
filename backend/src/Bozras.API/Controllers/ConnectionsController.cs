using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Bozras.Application.DTOs.Connections.Request;
using Bozras.Application.Interfaces.Services;
using Bozras.Domain.Constants;

namespace Bozras.API.Controllers;

[Route("api/connections")]
[Authorize(Roles = RoleNames.Shop)]
public class ConnectionsController : ApiControllerBase
{
    private readonly IShopConnectionService _service;

    public ConnectionsController(IShopConnectionService service)
    {
        _service = service;
    }

    [HttpGet("profile")]
    public async Task<IActionResult> GetProfile(CancellationToken ct) =>
        ToActionResult(await _service.GetProfileAsync(CurrentUserId, ct));

    [HttpPut("profile")]
    public async Task<IActionResult> SaveProfile([FromBody] SaveShopProfileRequest request, CancellationToken ct) =>
        ToActionResult(await _service.SaveProfileAsync(CurrentUserId, request, ct));

    [HttpGet("suppliers/nearby")]
    public async Task<IActionResult> GetNearby([FromQuery] string? search, CancellationToken ct) =>
        ToActionResult(await _service.GetNearbyAsync(CurrentUserId, search, ct));

    [HttpGet("suppliers")]
    public async Task<IActionResult> GetMySuppliers(CancellationToken ct) =>
        ToActionResult(await _service.GetMySuppliersAsync(CurrentUserId, ct));

    [HttpPost("suppliers/connect")]
    public async Task<IActionResult> Connect([FromBody] ConnectSupplierRequest request, CancellationToken ct) =>
        ToActionResult(await _service.ConnectAsync(CurrentUserId, request, ct));
    
    [HttpPost("suppliers/{supplierId:guid}/connect")]
    public async Task<IActionResult> ConnectTo(Guid supplierId, CancellationToken ct) =>
        ToActionResult(await _service.ConnectToSupplierAsync(CurrentUserId, supplierId, ct));
}