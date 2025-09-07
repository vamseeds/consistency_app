import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../services/category_service.dart';
import '../models/category.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final CategoryService _categoryService = CategoryService();
  List<Category> categories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final fetchedCategories = await _categoryService.fetchCategories();
      setState(() {
        categories = fetchedCategories;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load categories: $e')),
      );
    }
  }

  Future<IconData?> _showIconPicker(BuildContext context, {IconData? currentIcon}) async {
    // List of selectable Material Icons
    final List<IconData> allIcons = [
      Icons.work,
      Icons.fitness_center,
      Icons.home,
      Icons.school,
      Icons.star,
      Icons.favorite,
      Icons.event,
      Icons.shopping_cart,
      Icons.book,
      Icons.music_note,
      Icons.travel_explore,
      Icons.local_cafe,
      Icons.pets, 
      Icons.gamepad,

      // Add more as needed
    ];

    // Exclude current icon (if editing)
    final availableIcons = currentIcon != null
        ? allIcons.where((icon) => icon != currentIcon).toList()
        : allIcons;

    IconData? selectedIcon;

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Pick an Icon'),
        content: Container(
          width: 320,
          height: 400,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 60,
              childAspectRatio: 1,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: availableIcons.length,
            itemBuilder: (_, index) => GestureDetector(
              onTap: () {
                selectedIcon = availableIcons[index];
                Navigator.of(dialogContext).pop();
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: selectedIcon == availableIcons[index]
                      ? Colors.blue.withOpacity(0.2)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  availableIcons[index],
                  size: 30,
                  color: selectedIcon == availableIcons[index]
                      ? Colors.blue
                      : Colors.grey,
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    return selectedIcon;
  }

  Future<void> _addOrEditCategory({Category? category}) async {
    final TextEditingController nameController = TextEditingController(text: category?.name ?? '');
    IconData selectedIcon = category?.icon ?? Icons.category;
    Color selectedColor = category?.color ?? Colors.grey;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(category == null ? 'Add Category' : 'Edit Category'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  Row(
                    children: [
                      const Text('Icon: '),
                      IconButton(
                        icon: Icon(selectedIcon, color: selectedColor),
                        onPressed: () async {
                          final newIcon = await _showIconPicker(
                            context,
                            currentIcon: category?.icon, // Pass current icon to exclude
                          );
                          if (newIcon != null) {
                            setDialogState(() {
                              selectedIcon = newIcon;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('Color: '),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: selectedColor),
                        onPressed: () {
                          showDialog(
                            context: dialogContext,
                            builder: (colorContext) => AlertDialog(
                              title: const Text('Pick Color'),
                              content: SingleChildScrollView(
                                child: BlockPicker(
                                  pickerColor: selectedColor,
                                  onColorChanged: (color) {
                                    setDialogState(() {
                                      selectedColor = color;
                                    });
                                  },
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(colorContext),
                                  child: const Text('Done'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Text('Pick Color'),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Category name cannot be empty')),
                      );
                      return;
                    }
                    final newCategory = Category(
                      id: category?.id,
                      name: nameController.text.trim(),
                      icon: selectedIcon,
                      color: selectedColor,
                    );
                    try {
                      if (category == null) {
                        await _categoryService.createCategory(newCategory);
                      } else {
                        await _categoryService.updateCategory(newCategory);
                      }
                      await _fetchCategories();
                      Navigator.pop(dialogContext);
                    } catch (e) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text('Failed to save category: $e')),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return ListTile(
                  leading: Icon(category.icon, color: category.color),
                  title: Text(category.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _addOrEditCategory(category: category),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          try {
                            await _categoryService.deleteCategory(category.id!);
                            await _fetchCategories();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to delete category: $e')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addOrEditCategory,
        child: const Icon(Icons.add),
      ),
    );
  }
}
