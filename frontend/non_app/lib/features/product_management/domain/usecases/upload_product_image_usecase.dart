import '../repository/product_management_repository.dart';

class UploadProductImageUseCase {
  UploadProductImageUseCase(this._repository);

  final ProductManagementRepository _repository;

  Future<String> call(String filePath) => _repository.uploadImage(filePath);
}