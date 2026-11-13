using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Bozras.Application.DTOs.Locations.Request;
using Bozras.Application.Interfaces.Services;
using Bozras.Domain.Constants;

namespace Bozras.API.Controllers;

[Route("api/locations")]
[Authorize]
public class LocationsController : ApiControllerBase
{
    private readonly ILocationService _locationService;

    public LocationsController(ILocationService locationService)
    {
        _locationService = locationService;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll(CancellationToken ct)
    {
        return ToActionResult(await _locationService.GetAllAsync(ct));
    }

    [HttpPost]
    [Authorize(Roles = RoleNames.SuperAdmin)]
    public async Task<IActionResult> Create([FromBody] SaveLocationRequest request, CancellationToken ct)
    {
        return ToActionResult(await _locationService.CreateAsync(request, ct));
    }

    [HttpPut("{id:guid}")]
    [Authorize(Roles = RoleNames.SuperAdmin)]
    public async Task<IActionResult> Update(Guid id, [FromBody] SaveLocationRequest request, CancellationToken ct)
    {
        return ToActionResult(await _locationService.UpdateAsync(id, request, ct));
    }

    [HttpDelete("{id:guid}")]
    [Authorize(Roles = RoleNames.SuperAdmin)]
    public async Task<IActionResult> Delete(Guid id, CancellationToken ct)
    {
        return ToActionResult(await _locationService.DeleteAsync(id, ct));
    }
}