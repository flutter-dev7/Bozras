using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Bozras.Application.DTOs.Suppliers.Request;
using Bozras.Application.Interfaces.Services;
using Bozras.Domain.Constants;

namespace Bozras.API.Controllers;

[Route("api/superadmin/suppliers")]
[Authorize(Roles = RoleNames.SuperAdmin)]
public class SuppliersController : ApiControllerBase
{
    private readonly ISupplierService _supplierService;

    public SuppliersController(ISupplierService supplierService)
    {
        _supplierService = supplierService;
    }

    [HttpGet]
    public async Task<IActionResult> GetPaged([FromQuery] SupplierQueryRequest request, CancellationToken ct)
    {
        return ToActionResult(await _supplierService.GetPagedAsync(request, ct));
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id, CancellationToken ct)
    {
        return ToActionResult(await _supplierService.GetByIdAsync(id, ct));
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateSupplierRequest request, CancellationToken ct)
    {
        return ToActionResult(await _supplierService.CreateAsync(request, ct));
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateSupplierRequest request, CancellationToken ct)
    {
        return ToActionResult(await _supplierService.UpdateAsync(id, request, ct));
    }

    [HttpPost("{id:guid}/regenerate-code")]
    public async Task<IActionResult> RegenerateCode(Guid id, CancellationToken ct)
    {
        return ToActionResult(await _supplierService.RegenerateCodeAsync(id, ct));
    }

    [HttpGet("{id:guid}/payments")]
    public async Task<IActionResult> GetPayments(Guid id, CancellationToken ct)
    {
        return ToActionResult(await _supplierService.GetPaymentsAsync(id, ct));
    }

    [HttpPost("{id:guid}/payments")]
    public async Task<IActionResult> RecordPayment(
        Guid id, [FromBody] RecordSubscriptionPaymentRequest request, CancellationToken ct)
    {
        return ToActionResult(await _supplierService.RecordPaymentAsync(id, request, CurrentUserId, ct));
    }
}