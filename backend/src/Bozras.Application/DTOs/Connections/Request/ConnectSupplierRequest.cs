using System.ComponentModel.DataAnnotations;

namespace Bozras.Application.DTOs.Connections.Request;

public class ConnectSupplierRequest
{
    [Required, MaxLength(50)]
    public string Code { get; set; } = string.Empty;
}