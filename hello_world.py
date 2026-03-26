import pathlib

from gaphor.application import Session
from gaphor import UML
from gaphor.UML.classes import ClassItem
from gaphor.storage import save
from gaphor.diagram.export import save_svg

pathlib.Path("out").mkdir(exist_ok=True)

# Headless session — no GUI, but provides modeling language and element services
session = Session(
    services=[
        "event_manager",
        "component_registry",
        "element_factory",
        "element_dispatcher",
        "modeling_language",
    ]
)
factory = session.get_service("element_factory")

# Create a top-level package
pkg = factory.create(UML.Package)
pkg.name = "HelloWorld"

# Create a class inside the package
greeter = factory.create(UML.Class)
greeter.name = "Greeter"
pkg.packagedElement.append(greeter)

# Add an attribute
name_attr = factory.create(UML.Property)
name_attr.name = "name"
greeter.ownedAttribute.append(name_attr)

# Add a method
greet_op = factory.create(UML.Operation)
greet_op.name = "greet"
greeter.ownedOperation.append(greet_op)

# Create a diagram and place the class on it
diagram = factory.create(UML.ClassDiagram)
diagram.name = "HelloWorld Class Diagram"
diagram.element = pkg

class_item = diagram.create(ClassItem, subject=greeter)
class_item.matrix.translate(50, 50)

# Save model
with open("out/hello_world.gaphor", "w", encoding="utf-8") as f:
    save(f, factory)

# Export SVG
save_svg("out/hello_world.svg", diagram)

print("Model saved to out/hello_world.gaphor")
print("SVG exported to out/hello_world.svg")
print(f"  Package:   {pkg.name}")
print(f"  Class:     {greeter.name}")
print(f"  Attribute: {name_attr.name}")
print(f"  Operation: {greet_op.name}()")
