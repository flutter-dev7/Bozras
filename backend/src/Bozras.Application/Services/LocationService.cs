using Bozras.Application.Common;
using Bozras.Application.DTOs.Locations.Request;
using Bozras.Application.DTOs.Locations.Response;
using Bozras.Application.Interfaces.Repositories;
using Bozras.Application.Interfaces.Services;
using Bozras.Domain.Entities;
using Bozras.Domain.Enums;

namespace Bozras.Application.Services;

public class LocationService : ILocationService
{
    private readonly ILocationRepository _locations;
    private readonly IUnitOfWork _unitOfWork;

    public LocationService(ILocationRepository locations, IUnitOfWork unitOfWork)
    {
        _locations = locations;
        _unitOfWork = unitOfWork;
    }

    public async Task<Result<List<LocationResponse>>> GetAllAsync(CancellationToken ct = default)
    {
        var locations = await _locations.GetAllAsync(ct);

        return Result<List<LocationResponse>>.Success(locations.Select(ToResponse).ToList());
    }

    public async Task<Result<LocationResponse>> CreateAsync(
        SaveLocationRequest request, CancellationToken ct = default)
    {
        var name = request.Name.Trim();

        var error = await ValidateAsync(name, request, null, ct);
        if (error is not null)
            return Result<LocationResponse>.Failure(error.Value.Message, error.Value.Type);

        var location = new Location
        {
            Name = name,
            Type = request.Type,
            ParentId = request.ParentId,
            IsActive = request.IsActive
        };

        await _locations.AddAsync(location, ct);
        await _unitOfWork.SaveChangesAsync(ct);

        return Result<LocationResponse>.Success(ToResponse(location));
    }

    public async Task<Result<LocationResponse>> UpdateAsync(
        Guid id, SaveLocationRequest request, CancellationToken ct = default)
    {
        var location = await _locations.GetByIdAsync(id, ct);
        if (location is null)
            return Result<LocationResponse>.Failure("Не найдено.", ErrorType.NotFound);

        var name = request.Name.Trim();

        var error = await ValidateAsync(name, request, id, ct);
        if (error is not null)
            return Result<LocationResponse>.Failure(error.Value.Message, error.Value.Type);

        if (request.Type != location.Type && await _locations.HasChildrenAsync(id, ct))
            return Result<LocationResponse>.Failure("Нельзя менять тип, пока есть вложенные элементы.");

        location.Name = name;
        location.Type = request.Type;
        location.ParentId = request.ParentId;
        location.IsActive = request.IsActive;

        await _unitOfWork.SaveChangesAsync(ct);

        return Result<LocationResponse>.Success(ToResponse(location));
    }

    public async Task<Result<bool>> DeleteAsync(Guid id, CancellationToken ct = default)
    {
        var location = await _locations.GetByIdAsync(id, ct);
        if (location is null)
            return Result<bool>.Failure("Не найдено.", ErrorType.NotFound);

        if (await _locations.HasChildrenAsync(id, ct))
            return Result<bool>.Failure("Сначала удалите вложенные города и районы.", ErrorType.Conflict);

        if (await _locations.IsUsedByServiceAreasAsync(id, ct))
            return Result<bool>.Failure(
                "Это место указано в зонах доставки поставщиков. Отключите его вместо удаления.", ErrorType.Conflict);

        _locations.Remove(location);
        await _unitOfWork.SaveChangesAsync(ct);

        return Result<bool>.Success(true);
    }

    private async Task<(string Message, ErrorType Type)?> ValidateAsync(
        string name, SaveLocationRequest request, Guid? selfId, CancellationToken ct)
    {
        if (name.Length == 0)
            return ("Укажите название.", ErrorType.Validation);

        Location? parent = null;

        if (request.ParentId.HasValue)
        {
            if (request.ParentId == selfId)
                return ("Нельзя вложить элемент в самого себя.", ErrorType.Validation);

            parent = await _locations.GetByIdAsync(request.ParentId.Value, ct);
            if (parent is null)
                return ("Родитель не найден.", ErrorType.NotFound);
        }

        var hierarchyError = request.Type switch
        {
            LocationType.Region => parent is null ? null : "Область не может входить в другое место.",
            LocationType.City => parent is null || parent.Type == LocationType.Region
                ? null
                : "Город может входить только в область.",
            LocationType.District => parent is not null && parent.Type != LocationType.District
                ? null
                : "Район должен входить в город или область.",
            _ => "Неизвестный тип."
        };

        if (hierarchyError is not null)
            return (hierarchyError, ErrorType.Validation);

        if (await _locations.NameExistsAsync(request.ParentId, name, selfId, ct))
            return ("Такое название уже есть на этом уровне.", ErrorType.Conflict);

        return null;
    }

    private static LocationResponse ToResponse(Location location) => new()
    {
        Id = location.Id,
        Name = location.Name,
        Type = location.Type.ToString(),
        ParentId = location.ParentId,
        IsActive = location.IsActive
    };
}