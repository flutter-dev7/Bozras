using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Bozras.Application.DTOs.Plans.Request;
using Bozras.Application.Interfaces.Services;
using Bozras.Domain.Constants;

namespace Bozras.API.Controllers;

[Route("api/superadmin/plans")]
[Authorize(Roles = RoleNames.SuperAdmin)]
public class PlansController : ApiControllerBase
{
    private readonly IPlanService _planService;

    public PlansController(IPlanService planService)
    {
        _planService = planService;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll(CancellationToken ct)
    {
        return ToActionResult(await _planService.GetAllAsync(ct));
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] SavePlanRequest request, CancellationToken ct)
    {
        return ToActionResult(await _planService.CreateAsync(request, ct));
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] SavePlanRequest request, CancellationToken ct)
    {
        return ToActionResult(await _planService.UpdateAsync(id, request, ct));
    }
}