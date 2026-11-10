using System.ComponentModel.DataAnnotations;

namespace Bozras.Application.DTOs.Suppliers.Request;

public class CreateSupplierRequest
{
    [Required, StringLength(200)]
    public string Name { get; set; } = string.Empty;

    [StringLength(30)]
    public string? Phone { get; set; }

    [StringLength(500)]
    public string? Description { get; set; }

    public Guid? PlanId { get; set; }

    public bool RequiresApproval { get; set; }

    public List<Guid> LocationIds { get; set; } = new();

    [Required, StringLength(100)]
    public string AdminFirstName { get; set; } = string.Empty;

    [Required, StringLength(100)]
    public string AdminLastName { get; set; } = string.Empty;

    [Required, StringLength(200)]
    public string AdminEmail { get; set; } = string.Empty;

    [Required, StringLength(30)]
    public string AdminPhone { get; set; } = string.Empty;
}