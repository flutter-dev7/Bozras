using Bozras.Application.Common;
using Bozras.Application.DTOs.Users.Request;
using Bozras.Application.DTOs.Users.Response;

namespace Bozras.Application.Interfaces.Services;

public interface IUserService
{
    Task<Result<PagedResult<UserDetailsResponse>>> GetPagedAsync(UserQueryRequest request, CancellationToken ct = default);

    Task<Result<UserDetailsResponse>> GetByIdAsync(Guid id, CancellationToken ct = default);

    Task<Result<UserDetailsResponse>> CreateAsync(CreateUserRequest request, CancellationToken ct = default);

    Task<Result<UserDetailsResponse>> UpdateAsync(
        Guid id, UpdateUserRequest request, Guid currentUserId, CancellationToken ct = default);
}