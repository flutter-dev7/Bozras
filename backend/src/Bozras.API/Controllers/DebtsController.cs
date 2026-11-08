using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Bozras.Application.DTOs.Debts.Request;
using Bozras.Application.Interfaces.Services;
using Bozras.Domain.Constants;

namespace Bozras.API.Controllers;

[Route("api/[controller]")]
[Authorize(Roles = RoleNames.Admin)]
public class DebtsController : ApiControllerBase
{
    private readonly IDebtService _debtService;

    public DebtsController(IDebtService debtService)
    {
        _debtService = debtService;
    }

    [HttpGet]
    public async Task<IActionResult> GetDebts([FromQuery] DebtQueryRequest request, CancellationToken ct)
    {
        return ToActionResult(await _debtService.GetDebtsAsync(request, ct));
    }
}