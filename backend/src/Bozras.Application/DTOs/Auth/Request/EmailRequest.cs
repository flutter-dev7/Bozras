using System.ComponentModel.DataAnnotations;

namespace Bozras.Application.DTOs.Auth.Request;

public class EmailRequest
{
    [Required]
    [StringLength(254)]
    public string Email { get; set; } = string.Empty;
}