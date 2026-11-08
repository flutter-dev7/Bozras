using System.Security.Claims;
using Bozras.API.Http;
using Bozras.Application.Interfaces.Services;
using Bozras.Domain.Constants;
using Bozras.Domain.Enums;

namespace Bozras.API.Middleware;

public class TenantMiddleware
{
    public const string SupplierHeader = "X-Supplier-Id";

    private readonly RequestDelegate _next;

    public TenantMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context, ITenantContext tenant, ITenantAccessService access)
    {
        if (context.User.Identity?.IsAuthenticated != true)
        {
            await _next(context);
            return;
        }

        var ct = context.RequestAborted;
        var role = context.User.FindFirst("role")?.Value;

        var headerRaw = context.Request.Headers[SupplierHeader].ToString();
        var hasHeader = !string.IsNullOrWhiteSpace(headerRaw);
        var headerId = Guid.Empty;

        if (hasHeader && !Guid.TryParse(headerRaw, out headerId))
        {
            await ApiResponses.WriteAsync(
                context, StatusCodes.Status400BadRequest, "Некорректный поставщик.", ErrorType.Validation);
            return;
        }

        if (role == RoleNames.SuperAdmin)
        {
            if (hasHeader)
            {
                if (!await access.SupplierExistsAsync(headerId, ct))
                {
                    await ApiResponses.WriteAsync(
                        context, StatusCodes.Status404NotFound, "Поставщик не найден.", ErrorType.NotFound);
                    return;
                }

                tenant.Set(headerId);
                context.User = AsAdmin(context.User);
            }

            await _next(context);
            return;
        }

        if (role == RoleNames.Shop)
        {
            if (hasHeader)
            {
                var subject = context.User.FindFirst("sub")?.Value;

                if (!Guid.TryParse(subject, out var userId)
                    || !await access.IsShopConnectedAsync(userId, headerId, ct))
                {
                    await ApiResponses.WriteAsync(
                        context, StatusCodes.Status403Forbidden,
                        "Вы не подключены к этому поставщику.", ErrorType.Forbidden);
                    return;
                }

                if (!await access.IsSupplierAvailableAsync(headerId, ct))
                {
                    await ApiResponses.WriteAsync(
                        context, StatusCodes.Status403Forbidden,
                        "Поставщик временно недоступен.", ErrorType.Forbidden);
                    return;
                }

                tenant.Set(headerId);
            }

            await _next(context);
            return;
        }

        if (!Guid.TryParse(context.User.FindFirst("supplier_id")?.Value, out var supplierId))
        {
            await ApiResponses.WriteAsync(
                context, StatusCodes.Status403Forbidden,
                "Сотрудник не привязан к поставщику.", ErrorType.Forbidden);
            return;
        }

        if (!await access.IsSupplierAvailableAsync(supplierId, ct))
        {
            await ApiResponses.WriteAsync(
                context, StatusCodes.Status403Forbidden,
                "Доступ поставщика приостановлен. Обратитесь к администратору сервиса.", ErrorType.Forbidden);
            return;
        }

        tenant.Set(supplierId);

        await _next(context);
    }

    private static ClaimsPrincipal AsAdmin(ClaimsPrincipal principal)
    {
        var claims = principal.Claims
            .Where(c => c.Type != "role")
            .Append(new Claim("role", RoleNames.Admin));

        return new ClaimsPrincipal(new ClaimsIdentity(claims, "Impersonation", "name", "role"));
    }
}