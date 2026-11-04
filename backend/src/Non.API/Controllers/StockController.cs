using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Non.Application.DTOs.Stock.Request;
using Non.Application.Interfaces.Services;
using Non.Domain.Constants;

namespace Non.API.Controllers;

[Route("api/[controller]")]
[Authorize(Roles = RoleNames.Admin)]
public class StockController : ApiControllerBase
{
    private readonly IStockService _stockService;

    public StockController(IStockService stockService)
    {
        _stockService = stockService;
    }

    [HttpPost("receipts")]
    public async Task<IActionResult> Receive([FromBody] ReceiveStockRequest request, CancellationToken ct)
    {
        return ToActionResult(await _stockService.ReceiveAsync(request, CurrentUserId, ct));
    }

    [HttpPost("write-offs")]
    public async Task<IActionResult> WriteOff([FromBody] WriteOffStockRequest request, CancellationToken ct)
    {
        return ToActionResult(await _stockService.WriteOffAsync(request, CurrentUserId, ct));
    }

    [HttpGet("movements")]
    public async Task<IActionResult> GetMovements([FromQuery] StockMovementQueryRequest request, CancellationToken ct)
    {
        return ToActionResult(await _stockService.GetMovementsAsync(request, ct));
    }
}