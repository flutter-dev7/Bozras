using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Bozras.Application.DTOs.Connections.Request;
using Bozras.Application.Interfaces.Services;
using Bozras.Domain.Constants;

namespace Bozras.API.Controllers;

[Route("api/supplier")]
[Authorize(Roles = RoleNames.Admin)]
public class SupplierProfileController : ApiControllerBase
{
    private readonly ISupplierProfileService _service;

    public SupplierProfileController(ISupplierProfileService service)
    {
        _service = service;
    }

    [HttpGet]
    public async Task<IActionResult> Get(CancellationToken ct) =>
        ToActionResult(await _service.GetAsync(ct));

    [HttpPut]
    public async Task<IActionResult> Update([FromBody] UpdateSupplierProfileRequest request, CancellationToken ct) =>
        ToActionResult(await _service.UpdateAsync(request, ct));

    [HttpPost("regenerate-code")]
    public async Task<IActionResult> RegenerateCode(CancellationToken ct) =>
        ToActionResult(await _service.RegenerateCodeAsync(ct));
}