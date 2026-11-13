using System.ComponentModel.DataAnnotations;

namespace Bozras.Application.DTOs.Connections.Request;

public class UpdateSupplierProfileRequest
{
    [MaxLength(30)]
    public string? Phone { get; set; }

    [MaxLength(500)]
    public string? Description { get; set; }

    public bool RequiresApproval { get; set; }
}