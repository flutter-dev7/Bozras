using System.ComponentModel.DataAnnotations;

namespace Bozras.Application.DTOs.Auth.Request;

public class RefreshTokenRequest
{
    [Required]
    [StringLength(200, MinimumLength = 20)]
    public string RefreshToken { get; set; } = string.Empty;
}