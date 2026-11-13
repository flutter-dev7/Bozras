using Bozras.Application.Common;
using Bozras.Domain.Enums;

namespace Bozras.Application.DTOs.Users.Request;

public class UserQueryRequest : PaginationRequest
{
    public string? Search { get; set; }
    public UserRole? Role { get; set; }
    public bool? IsActive { get; set; }
}