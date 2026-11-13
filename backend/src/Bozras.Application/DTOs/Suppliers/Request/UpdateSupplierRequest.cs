using System.ComponentModel.DataAnnotations;

namespace Bozras.Application.DTOs.Suppliers.Request;

public class UpdateSupplierRequest
{
    [Required, StringLength(200)]
    public string Name { get; set; } = string.Empty;

    [StringLength(30)]
    public string? Phone { get; set; }

    [StringLength(500)]
    public string? Description { get; set; }

    public Guid? PlanId { get; set; }

    public bool RequiresApproval { get; set; }

    public bool IsActive { get; set; } = true;

    public List<Guid> LocationIds { get; set; } = new();
}